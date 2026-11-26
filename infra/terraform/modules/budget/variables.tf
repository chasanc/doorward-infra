variable "name" {
  description = "Name prefix."
  type        = string
}

variable "limit_usd" {
  description = "Monthly account spend limit in USD."
  type        = number
}

variable "email" {
  description = "Address that receives the alerts. Not committed: pass it with TF_VAR_budget_email."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+$", var.email))
    error_message = "email must be a valid address."
  }
}
