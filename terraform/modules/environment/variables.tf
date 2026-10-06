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
    variables           = optional(map(string), {})
    secrets             = optional(list(string), [])
    reviewers           = optional(list(string), [])
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
  validation {
    condition     = try(alltrue([for n in concat(keys(var.environment.variables), var.environment.secrets) : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", n)) && !startswith(upper(n), "GITHUB_")]), false)
    error_message = "Repository ${var.repository}, environment ${try(coalesce(var.environment.name), "")}: invalid variable or secret name(s) ${try(join(", ", [for n in concat(keys(var.environment.variables), var.environment.secrets) : n if !can(regex("^[A-Za-z_][A-Za-z0-9_]*$", n)) || startswith(upper(n), "GITHUB_")]), "")}; each must be A-Z, a-z, 0-9, _, not starting with a digit or GITHUB_."
  }
  validation {
    condition     = try(length(distinct([for n in keys(var.environment.variables) : upper(n)])) == length(var.environment.variables) && length(distinct([for n in var.environment.secrets : upper(n)])) == length(var.environment.secrets), false)
    error_message = "Repository ${var.repository}, environment ${try(coalesce(var.environment.name), "")}: variable and secret names must be unique (case-insensitive)."
  }
  validation {
    condition     = try(alltrue([for u in var.environment.reviewers : trimspace(u) != ""]), false)
    error_message = "Repository ${var.repository}, environment ${try(coalesce(var.environment.name), "")}: reviewers must be non-empty GitHub usernames."
  }
}
