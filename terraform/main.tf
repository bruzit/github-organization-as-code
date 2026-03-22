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
}
