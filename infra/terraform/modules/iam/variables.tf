variable "name" {
  description = "Name prefix, also the ECS cluster/service name (e.g. doorward-qa)."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "stage" {
  description = "qa or prod. Decides which GitHub OIDC subject may assume the deploy role."
  type        = string

  validation {
    condition     = contains(["qa", "prod"], var.stage)
    error_message = "stage must be qa or prod."
  }
}

variable "github_repo" {
  description = "GitHub repository that runs the deploy workflows, as owner/name."
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Only one per AWS account; set false where it already exists."
  type        = bool
}

variable "ecr_repository_arn" {
  description = "ARN of this stage's ECR repository."
  type        = string
}

variable "ecr_pull_repository_arns" {
  description = "Extra ECR repositories the deploy role may read (PROD reads the QA repository)."
  type        = list(string)
  default     = []
}
