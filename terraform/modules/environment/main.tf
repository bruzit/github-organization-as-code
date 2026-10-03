resource "github_repository_environment" "this" {
  repository        = var.repository
  environment       = var.environment.name
  can_admins_bypass = false

  dynamic "deployment_branch_policy" {
    for_each = var.environment.deployment_branches == null ? [] : [true]

    content {
      protected_branches     = false
      custom_branch_policies = true
    }
  }
}

resource "github_repository_environment_deployment_policy" "this" {
  for_each = toset(var.environment.deployment_branches == null ? [] : var.environment.deployment_branches)

  repository     = var.repository
  environment    = github_repository_environment.this.environment
  branch_pattern = each.value == "~DEFAULT_BRANCH" ? var.default_branch : each.value
}
