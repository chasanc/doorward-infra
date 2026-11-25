variable "region" {
  description = "AWS region."
  type        = string
}

variable "app_name" {
  description = "Application name; prefixes all resource names."
  type        = string
  default     = "doorward"
}

variable "environment" {
  description = "Deployment environment: dev (the QA stage) or prod (the PROD stage)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "github_repo" {
  description = "GitHub repository (owner/name) whose workflows deploy to this environment."
  type        = string
  default     = "chasanc/doorward"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. One per AWS account: true in dev, false in prod when they share an account."
  type        = bool
}

variable "create_budget" {
  description = "Create the account-wide monthly budget alert. One per account: true in dev."
  type        = bool
  default     = false
}

variable "budget_limit_usd" {
  description = "Monthly spend limit that triggers the budget alerts."
  type        = number
  default     = 100
}

variable "budget_email" {
  description = "Alert recipient. Not committed: set TF_VAR_budget_email when create_budget is true."
  type        = string
  default     = "unset@example.invalid"

  validation {
    condition     = !var.create_budget || !endswith(var.budget_email, ".invalid")
    error_message = "Set budget_email (TF_VAR_budget_email) when create_budget is true."
  }
}

variable "db_multi_az" {
  description = "Run the database with a standby in a second AZ (about double the cost)."
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "image_retention_count" {
  description = "Tagged images kept in the ECR repository (cost guardrail)."
  type        = number
  default     = 20
}

variable "desired_count" {
  description = "Initial number of Fargate tasks."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (cost guardrail: 14 to 30)."
  type        = number
  default     = 14
}
