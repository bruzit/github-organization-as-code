locals {
  config = yamldecode(file(var.config))

  allowed_top_level_keys  = ["repositories"]
  allowed_repository_keys = ["name", "description", "homepage_url", "topics", "is_template", "template"]

  repository_defaults = {
    description  = null
    homepage_url = null
    topics       = null
    is_template  = null
    template     = null
  }

  repositories = {
    for repository in local.config.repositories :
    repository.name => merge(local.repository_defaults, repository)
  }
}

resource "github_repository" "this" {
  for_each = local.repositories

  name = each.key

  # Metadata
  description  = each.value.description
  homepage_url = each.value.homepage_url
  topics       = each.value.topics

  # Properties
  archive_on_destroy = true
  is_template        = each.value.is_template

  # Contents
  dynamic "template" {
    for_each = each.value.template == null ? [] : [each.value.template]

    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = try(template.value.include_all_branches, false)
    }
  }

  lifecycle {
    precondition {
      condition     = length(setsubtract(keys(local.config), local.allowed_top_level_keys)) == 0
      error_message = "Unknown top-level key(s) in ${var.config}: ${join(", ", setsubtract(keys(local.config), local.allowed_top_level_keys))}"
    }
    precondition {
      condition     = length(setsubtract(keys(each.value), local.allowed_repository_keys)) == 0
      error_message = "Unknown key(s) for repository ${each.key}: ${join(", ", setsubtract(keys(each.value), local.allowed_repository_keys))}"
    }
  }
}
