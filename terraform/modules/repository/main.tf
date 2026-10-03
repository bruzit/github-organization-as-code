resource "github_repository" "this" {
  name = var.repository.name

  # Metadata
  description  = var.repository.description
  homepage_url = var.repository.homepage_url
  topics       = var.repository.topics

  # Properties
  archive_on_destroy     = true
  delete_branch_on_merge = true
  is_template            = var.repository.is_template

  # Contents
  dynamic "template" {
    for_each = var.repository.template == null ? [] : [var.repository.template]

    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = template.value.include_all_branches
    }
  }
}

# github_repository.default_branch is deprecated.
data "github_repository" "this" {
  count = length(var.repository.environments) > 0 ? 1 : 0

  name = github_repository.this.name
}

module "environment" {
  source   = "../environment"
  for_each = var.repository.environments

  repository     = github_repository.this.name
  default_branch = data.github_repository.this[0].default_branch
  environment    = merge(each.value, { name = each.key })
}
