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
  description = "Deployment environment (dev or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "image_retention_count" {
  description = "Tagged images kept per ECR repository (cost guardrail)."
  type        = number
  default     = 20
}
