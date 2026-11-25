data "aws_caller_identity" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  log_group_arn = "arn:aws:logs:${var.region}:${local.account_id}:log-group:/ecs/${var.name}"
  service_arn   = "arn:aws:ecs:${var.region}:${local.account_id}:service/${var.name}/${var.name}"

  # QA deploys from main; PROD only from jobs that passed the `production` Environment gate.
  github_sub = var.stage == "qa" ? "repo:${var.github_repo}:ref:refs/heads/main" : "repo:${var.github_repo}:environment:production"
}

# ---------------------------------------------------------------- ECS task roles

data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

# Execution role: pull the image, write logs. Nothing else.
resource "aws_iam_role" "execution" {
  name               = "${var.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "execution" {
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# GetAuthorizationToken does not support resource-level permissions.
data "aws_iam_policy_document" "execution_ecr_auth" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execution_ecr_auth" {
  name   = "ecr-auth"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_ecr_auth.json
}

# Task role: the app's own identity. Empty on purpose; later milestones attach S3/secrets access.
resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

# ---------------------------------------------------------------- GitHub OIDC

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_sub]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.name}-deploy"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [var.ecr_repository_arn]
  }

  # PROD re-tags the exact QA image: read-only access to the QA repository.
  dynamic "statement" {
    for_each = length(var.ecr_pull_repository_arns) > 0 ? [1] : []

    content {
      sid       = "EcrPullSource"
      actions   = ["ecr:BatchGetImage", "ecr:DescribeImages", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability"]
      resources = var.ecr_pull_repository_arns
    }
  }

  statement {
    sid       = "EcsDeployService"
    actions   = ["ecs:UpdateService", "ecs:DescribeServices"]
    resources = [local.service_arn]
  }

  statement {
    sid       = "EcsTaskDefinition"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"] # Describe* on task definitions does not support resource-level permissions
  }

  statement {
    sid       = "EcsRegisterTaskDefinition"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"] # RegisterTaskDefinition does not support resource-level permissions
  }

  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution.arn, aws_iam_role.task.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# GetAuthorizationToken does not support resource-level permissions.
data "aws_iam_policy_document" "deploy_ecr_auth" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

resource "aws_iam_role_policy" "deploy_ecr_auth" {
  name   = "ecr-auth"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_ecr_auth.json
}
