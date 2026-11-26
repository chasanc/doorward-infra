data "aws_caller_identity" "current" {}

locals {
  # dev is the QA stage, prod is the PROD stage. Each has its own state, ECR repo and ECS service.
  stage = var.environment == "dev" ? "qa" : "prod"
  name  = "${var.app_name}-${local.stage}"

  # PROD promotes the exact image tested in QA, so its deploy role can read the QA repository.
  qa_repository_arn = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.app_name}-qa"
}

module "network" {
  source = "./modules/network"

  name = local.name
  cidr = var.vpc_cidr
}

module "ecr" {
  source = "./modules/ecr"

  name                  = local.name
  image_retention_count = var.image_retention_count
}

module "s3" {
  source = "./modules/s3"

  name          = local.name
  force_destroy = var.environment == "dev"
}

module "secrets" {
  source = "./modules/secrets"

  name = local.name
  # A deleted secret keeps its name reserved for the window, which blocks a dev teardown and rebuild.
  recovery_window_days = var.environment == "dev" ? 0 : 7
}

module "rds" {
  source = "./modules/rds"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  subnet_ids              = module.network.private_subnet_ids
  tasks_security_group_id = module.network.tasks_security_group_id
  log_retention_days      = var.log_retention_days
  deletion_protection     = var.environment == "prod"
  multi_az                = var.db_multi_az
}

# The budget is account-wide, so one environment owns it (like the OIDC provider).
module "budget" {
  count  = var.create_budget ? 1 : 0
  source = "./modules/budget"

  name      = var.app_name
  limit_usd = var.budget_limit_usd
  email     = var.budget_email
}

module "iam" {
  source = "./modules/iam"

  task_s3_bucket_arn = module.s3.bucket_arn
  task_secret_arns   = [module.secrets.secret_arn, module.rds.master_secret_arn]
  task_kms_key_arns  = [module.s3.kms_key_arn, module.secrets.kms_key_arn]

  name                     = local.name
  region                   = var.region
  stage                    = local.stage
  github_repo              = var.github_repo
  create_oidc_provider     = var.create_oidc_provider
  ecr_repository_arn       = module.ecr.repository_arn
  ecr_pull_repository_arns = local.stage == "prod" ? [local.qa_repository_arn] : []
}

module "ecs_service" {
  source = "./modules/ecs-service"

  name               = local.name
  region             = var.region
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.network.tasks_security_group_id]
  desired_count      = var.desired_count
  log_retention_days = var.log_retention_days
}
