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
