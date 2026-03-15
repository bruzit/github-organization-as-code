variable "config" {
  type        = string
  description = "GitHub Organization configuration YAML"
  validation {
    condition     = fileexists(var.config)
    error_message = "File ${var.config} doesn't exist."
  }
}
