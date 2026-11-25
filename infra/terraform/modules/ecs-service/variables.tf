variable "name" {
  description = "Name of the cluster, service, task family and log group suffix."
  type        = string
}

variable "region" {
  description = "AWS region (for the awslogs driver)."
  type        = string
}

variable "execution_role_arn" {
  description = "Task execution role ARN."
  type        = string
}

variable "task_role_arn" {
  description = "Task role ARN."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the tasks."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for the tasks."
  type        = list(string)
}

variable "bootstrap_image" {
  description = "Image for the first task definition only; CI replaces it on the first deploy."
  type        = string
  default     = "public.ecr.aws/nginx/nginx-unprivileged:stable"
}

variable "container_port" {
  description = "Container port."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate CPU units. 256 is the smallest size."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate memory in MiB. 512 is the smallest size for 256 CPU."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of tasks."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention (cost guardrail: 14 to 30 days)."
  type        = number
  default     = 14

  validation {
    condition     = var.log_retention_days >= 14 && var.log_retention_days <= 30
    error_message = "log_retention_days must be between 14 and 30."
  }
}
