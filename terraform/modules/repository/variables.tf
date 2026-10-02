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
  })
  description = "Repository configuration"
}
