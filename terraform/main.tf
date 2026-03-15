locals {
  config = yamldecode(file(var.config))
}

resource "github_repository" "this" {
  for_each = { for repository in local.config.repositories : repository.name => repository }

  name = each.value.name
}
