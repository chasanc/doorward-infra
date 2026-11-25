variable "name" {
  description = "Name prefix (e.g. doorward-qa)."
  type        = string
}

variable "recovery_window_days" {
  description = "Days a deleted secret can be restored (7 to 30; 0 deletes immediately)."
  type        = number
  default     = 7
}
