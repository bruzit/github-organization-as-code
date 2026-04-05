locals {
  config = yamldecode(file(var.config))
}

resource "github_repository" "this" {
  for_each = { for repository in local.config.repositories : repository.name => repository }

  name = each.value.name

  # Metadata
  description  = try(each.value.description, null)
  homepage_url = try(each.value.homepage_url, null)
  topics       = try(each.value.topics, null)

  # Properties
  is_template = try(each.value.is_template, null)

  # Contents
  dynamic "template" {
    for_each = (
      try(each.value.template, null) != null &&
      length(try(each.value.template, {})) > 0
    ) ? [each.value.template] : []

    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = try(template.value.include_all_branches, false)
    }
  }
}
