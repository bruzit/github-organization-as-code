variable "repository" {
  type = object({
    name         = string
    description  = optional(string)
    homepage_url = optional(string)
    topics       = optional(list(string))
    is_template  = optional(bool)
    template = optional(object({
      owner                = string
      repository           = string
      include_all_branches = optional(bool, false)
    }))
    environments = optional(map(object({
      deployment_branches = optional(list(string))
      variables           = optional(map(string), {})
      secrets             = optional(list(string), [])
    })), {})
    rulesets = optional(map(object({
      bypass_apps = optional(list(number), [])
    })), {})
  })
  description = "Repository configuration"
  validation {
    condition     = try(can(regex("^[A-Za-z0-9._-]{1,100}$", var.repository.name)) && !contains([".", ".."], var.repository.name), false)
    error_message = "Repository name \"${try(coalesce(var.repository.name), "")}\" must be 1-100 characters of A-Z, a-z, 0-9, ., -, _ other than \".\" and \"..\"."
  }
  validation {
    condition     = try(var.repository.topics == null ? true : alltrue([for t in var.repository.topics : can(regex("^[a-z0-9][a-z0-9-]{0,49}$", t))]), false)
    error_message = "Repository ${try(coalesce(var.repository.name), "")}: invalid topic(s) ${try(join(", ", [for t in var.repository.topics : "\"${t}\"" if !can(regex("^[a-z0-9][a-z0-9-]{0,49}$", t))]), "")}; each must be lowercase letters, digits, hyphens, start with a letter or digit, max 50 characters."
  }
  validation {
    condition     = try(var.repository.topics == null ? true : length(var.repository.topics) <= 20, false)
    error_message = "Repository ${try(coalesce(var.repository.name), "")}: at most 20 topics, got ${try(length(var.repository.topics), 0)}."
  }
  validation {
    condition     = try(var.repository.topics == null ? true : length(distinct(var.repository.topics)) == length(var.repository.topics), false)
    error_message = "Repository ${try(coalesce(var.repository.name), "")}: duplicate topic(s) ${try(join(", ", distinct([for i, t in var.repository.topics : t if contains(slice(var.repository.topics, 0, i), t)])), "")}."
  }
  validation {
    condition     = try(var.repository.homepage_url == null || var.repository.homepage_url == "" ? true : startswith(var.repository.homepage_url, "http://") || startswith(var.repository.homepage_url, "https://"), false)
    error_message = "Repository ${try(coalesce(var.repository.name), "")}: homepage_url \"${try(coalesce(var.repository.homepage_url), "")}\" must start with http:// or https://."
  }
  validation {
    condition     = try(var.repository.template == null ? true : trimspace(var.repository.template.owner) != "" && trimspace(var.repository.template.repository) != "", false)
    error_message = "Repository ${try(coalesce(var.repository.name), "")}: template owner and repository must be non-empty."
  }
  validation {
    condition     = try(alltrue([for r in values(var.repository.rulesets) : alltrue([for id in r.bypass_apps : id > 0 && floor(id) == id]) && length(distinct(r.bypass_apps)) == length(r.bypass_apps)]), false)
    error_message = "Repository ${try(coalesce(var.repository.name), "")}: ruleset bypass_apps must be distinct GitHub App IDs (positive integers)."
  }
}
