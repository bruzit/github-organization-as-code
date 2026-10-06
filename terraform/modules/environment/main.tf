data "github_user" "this" {
  for_each = toset(var.environment.reviewers)

  username = each.value
}

resource "github_repository_environment" "this" {
  repository          = var.repository
  environment         = var.environment.name
  can_admins_bypass   = false
  prevent_self_review = false

  dynamic "reviewers" {
    for_each = length(var.environment.reviewers) > 0 ? [true] : []

    content {
      users = [for u in var.environment.reviewers : tonumber(data.github_user.this[u].id)]
    }
  }

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

resource "github_actions_environment_variable" "this" {
  for_each = var.environment.variables

  repository    = var.repository
  environment   = github_repository_environment.this.environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_secret" "this" {
  for_each = toset(var.environment.secrets)

  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = each.value
  value       = "set-by-hand"

  # remote_updated_at: the "Redundant ignore_changes element" warning is wrong, without it a hand-set value is overwritten with the placeholder.
  lifecycle {
    ignore_changes = [value, remote_updated_at]
  }
}
