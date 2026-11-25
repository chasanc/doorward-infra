variable "app_name" {
  description = "Application name; repositories are named <app_name>-qa and <app_name>-prod."
  type        = string
}

variable "image_retention_count" {
  description = "Tagged images kept per repository."
  type        = number
}
