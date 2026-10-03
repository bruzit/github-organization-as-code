locals {
  config = try(yamldecode(file(var.config)), {})

  allowed_top_level_keys  = ["repositories"]
  allowed_repository_keys = ["name", "description", "homepage_url", "topics", "is_template", "template"]

  repositories = try({
    for repository in local.config.repositories :
    repository.name => repository
  }, {})
}

module "repository" {
  source   = "./modules/repository"
  for_each = local.repositories

  repository = each.value
}
