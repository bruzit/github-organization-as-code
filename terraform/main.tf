locals {
  config = try(yamldecode(file(var.config)), {})

  allowed_top_level_keys    = ["organization", "repositories"]
  allowed_organization_keys = ["environments"]
  allowed_repository_keys   = ["name", "description", "homepage_url", "topics", "is_template", "template", "environments"]
  allowed_environment_keys  = ["deployment_branches"]

  organization_environments = try({ for name, environment in local.config.organization.environments : name => environment }, {})

  repositories = try({
    for repository in local.config.repositories :
    repository.name => merge(repository, {
      environments = {
        for name, environment in merge(local.organization_environments, try({ for name, environment in repository.environments : name => environment }, {})) :
        name => environment if environment != null
      }
    })
  }, {})
}

module "repository" {
  source   = "./modules/repository"
  for_each = local.repositories

  repository = each.value
}
