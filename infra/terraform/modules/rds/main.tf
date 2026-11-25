resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "PostgreSQL: reachable only from the ECS tasks"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "from_tasks" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.tasks_security_group_id
}

# The task security group only allows HTTPS out, so it needs an explicit path to the database.
resource "aws_vpc_security_group_egress_rule" "tasks_to_db" {
  security_group_id            = var.tasks_security_group_id
  description                  = "PostgreSQL to the database"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
}

# RDS would create these log groups itself with no expiry; owning them keeps retention and encryption in our hands.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  log_exports = ["postgresql", "upgrade"]
  log_group_arns = [
    for e in local.log_exports :
    "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/instance/${var.name}/${e}"
  ]
}

data "aws_iam_policy_document" "logs_key" {
  statement {
    sid       = "AccountAdmin"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "CloudWatchLogsUse"
    actions   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = local.log_group_arns
    }
  }
}

resource "aws_kms_key" "logs" {
  description         = "${var.name} database log encryption"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.logs_key.json
}

resource "aws_cloudwatch_log_group" "db" {
  for_each = toset(local.log_exports)

  name              = "/aws/rds/instance/${var.name}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  storage_type          = "gp3"
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = "app_admin"
  # RDS generates the master password and keeps it in Secrets Manager: it never enters Terraform state.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  backup_retention_period             = var.backup_retention_days
  copy_tags_to_snapshot               = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"] # keep in step with local.log_exports

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name}-final" : null

  depends_on = [aws_cloudwatch_log_group.db]

  lifecycle {
    ignore_changes = [engine_version] # minor versions upgrade themselves
  }
}
