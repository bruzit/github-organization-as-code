variable "config" {
  type        = string
  description = "GitHub Organization configuration YAML"
  validation {
    condition     = fileexists(var.config)
    error_message = "File ${var.config} doesn't exist."
  }
  validation {
    condition     = !fileexists(var.config) || can(yamldecode(file(var.config)))
    error_message = "File ${var.config} is not a valid YAML document."
  }
  validation {
    condition     = !can(yamldecode(file(var.config))) || can(keys(yamldecode(file(var.config))))
    error_message = "File ${var.config}: top level must be a map."
  }
  validation {
    condition     = try(length(setsubtract(keys(yamldecode(file(var.config))), local.allowed_top_level_keys)) == 0, true)
    error_message = "Unknown top-level key(s) in ${var.config}: ${try(join(", ", setsubtract(keys(yamldecode(file(var.config))), local.allowed_top_level_keys)), "")}"
  }
  validation {
    condition     = !can(keys(yamldecode(file(var.config)))) || try(length(concat(yamldecode(file(var.config)).repositories, [])) > 0, false)
    error_message = "File ${var.config}: repositories must be a non-empty list (an empty one archives every repository)."
  }
  validation {
    condition     = try(alltrue([for r in concat(yamldecode(file(var.config)).repositories, []) : try(trimspace(r.name) != "", false)]), true)
    error_message = "File ${var.config}: every repository must be a map with a non-empty name."
  }
  validation {
    condition     = try(alltrue([for n, r in { for r in concat(yamldecode(file(var.config)).repositories, []) : lower(r.name) => r.name... } : length(r) == 1]), true)
    error_message = "Duplicate repository name(s) in ${var.config}: ${try(join(", ", flatten([for n, r in { for r in concat(yamldecode(file(var.config)).repositories, []) : lower(r.name) => r.name... } : r if length(r) > 1])), "")}"
  }
  validation {
    condition     = try(alltrue([for r in concat(yamldecode(file(var.config)).repositories, []) : length(setsubtract(keys(r), local.allowed_repository_keys)) == 0]), true)
    error_message = "Unknown repository key(s) in ${var.config}: ${try(join(", ", flatten([for r in concat(yamldecode(file(var.config)).repositories, []) : [for k in setsubtract(keys(r), local.allowed_repository_keys) : "${r.name}.${k}"]])), "")}"
  }
  validation {
    condition     = try(yamldecode(file(var.config)).organization == null, true) || try(length(setsubtract(keys(yamldecode(file(var.config)).organization), local.allowed_organization_keys)) == 0, false)
    error_message = "File ${var.config}: organization must be a map with key(s) ${join(", ", local.allowed_organization_keys)}; unknown: ${try(join(", ", setsubtract(keys(yamldecode(file(var.config)).organization), local.allowed_organization_keys)), "")}"
  }
  validation {
    condition     = try(length(flatten([for s in concat([{ label = "organization", environments = try(yamldecode(file(var.config)).organization.environments, null), opt_out = false }], [for r in yamldecode(file(var.config)).repositories : { label = r.name, environments = try(r.environments, null), opt_out = true }]) : s.environments == null ? [] : !can(keys(s.environments)) ? ["${s.label}.environments"] : [for n, e in s.environments : "${s.label}.environments.${n}" if !(s.opt_out && e == null) && !try(length(setsubtract(keys(e), local.allowed_environment_keys)) == 0, false)]])) == 0, true)
    error_message = "Invalid environment(s) in ${var.config}: ${try(join(", ", flatten([for s in concat([{ label = "organization", environments = try(yamldecode(file(var.config)).organization.environments, null), opt_out = false }], [for r in yamldecode(file(var.config)).repositories : { label = r.name, environments = try(r.environments, null), opt_out = true }]) : s.environments == null ? [] : !can(keys(s.environments)) ? ["${s.label}.environments"] : [for n, e in s.environments : "${s.label}.environments.${n}" if !(s.opt_out && e == null) && !try(length(setsubtract(keys(e), local.allowed_environment_keys)) == 0, false)]])), "")}; each must be a map of ${join(", ", local.allowed_environment_keys)}, or ~ under a repository to opt out of an organization environment."
  }
}
