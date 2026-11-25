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
