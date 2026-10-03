variable "repository" {
  type        = string
  description = "Repository name"
}

variable "default_branch" {
  type        = string
  description = "Repository default branch, substituted for ~DEFAULT_BRANCH in deployment_branches"
}

variable "environment" {
  type = object({
    name                = string
    deployment_branches = optional(list(string))
  })
  description = "Environment configuration"
  validation {
    condition     = try(trimspace(var.environment.name) != "", false)
    error_message = "Repository ${var.repository}: environment name must be non-empty."
  }
  validation {
    condition     = try(var.environment.deployment_branches == null ? true : length(var.environment.deployment_branches) > 0 && alltrue([for b in var.environment.deployment_branches : trimspace(b) != ""]) && length(distinct([for b in var.environment.deployment_branches : b == "~DEFAULT_BRANCH" ? var.default_branch : b])) == length(var.environment.deployment_branches), false)
    error_message = "Repository ${var.repository}, environment ${try(coalesce(var.environment.name), "")}: deployment_branches must be a non-empty list of distinct, non-empty patterns, ~DEFAULT_BRANCH resolved (omit it to allow every branch)."
  }
}
