variable "name" {
  description = "Name prefix and DB instance identifier."
  type        = string
}

variable "vpc_id" {
  description = "VPC the database lives in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the DB subnet group."
  type        = list(string)
}

variable "tasks_security_group_id" {
  description = "ECS tasks security group allowed to connect on 5432."
  type        = string
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "app"
}

variable "engine_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "Cost guardrail: smallest burstable class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial gp3 storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Standby replica in a second AZ (doubles the instance cost)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (cost guardrail: 14 to 30)."
  type        = number
  default     = 14

  validation {
    condition     = var.log_retention_days >= 14 && var.log_retention_days <= 30
    error_message = "log_retention_days must be between 14 and 30."
  }
}

variable "deletion_protection" {
  description = "Block deletion and take a final snapshot when it is removed. Enable in prod."
  type        = bool
  default     = false
}
