locals {
  config = try(yamldecode(file(var.config)), {})

  allowed_top_level_keys    = ["organization", "repositories"]
  allowed_organization_keys = ["environments", "rulesets"]
  allowed_repository_keys   = ["name", "description", "homepage_url", "topics", "is_template", "template", "environments", "rulesets"]
  allowed_environment_keys  = ["deployment_branches", "variables", "secrets", "reviewers"]
  allowed_ruleset_keys      = ["bypass_apps"]

  organization_environments = try({ for name, environment in local.config.organization.environments : name => environment }, {})
  organization_rulesets     = try({ for name, ruleset in local.config.organization.rulesets : name => ruleset }, {})

  repositories = try({
    for repository in local.config.repositories :
    repository.name => merge(repository, {
      environments = {
        for name, environment in merge(local.organization_environments, try({ for name, environment in repository.environments : name => environment }, {})) :
        name => environment if environment != null
      }
      rulesets = {
        for name, ruleset in merge(local.organization_rulesets, try({ for name, ruleset in repository.rulesets : name => ruleset }, {})) :
        name => ruleset if ruleset != null
      }
    })
  }, {})
}

module "repository" {
  source   = "./modules/repository"
  for_each = local.repositories

  repository = each.value
}
