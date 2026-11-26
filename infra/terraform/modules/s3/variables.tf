variable "name" {
  description = "Name prefix (e.g. doorward-qa)."
  type        = string
}

variable "noncurrent_version_days" {
  description = "Days before overwritten or deleted object versions expire (cost guardrail)."
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Allow destroying a non-empty bucket. Only for dev."
  type        = bool
  default     = false
}
