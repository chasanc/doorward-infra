variable "name" {
  description = "Repository name, e.g. doorward-qa."
  type        = string
}

variable "image_retention_count" {
  description = "Tagged images kept in the repository."
  type        = number
}
