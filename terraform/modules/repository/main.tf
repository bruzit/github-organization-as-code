resource "github_repository" "this" {
  name = var.repository.name

  # Metadata
  description  = var.repository.description
  homepage_url = var.repository.homepage_url
  topics       = var.repository.topics

  # Properties
  archive_on_destroy          = true
  allow_merge_commit          = false
  allow_rebase_merge          = true
  allow_squash_merge          = true
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  delete_branch_on_merge      = true
  has_issues                  = true
  is_template                 = var.repository.is_template

  # advanced_security omitted: setting it errors on public repositories.
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

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

resource "github_repository_ruleset" "this" {
  for_each = var.repository.rulesets

  repository  = github_repository.this.name
  name        = each.key
  target      = each.value.target
  enforcement = "active"

  conditions {
    ref_name {
      include = [each.value.target == "tag" ? "refs/tags/v*.*.*" : "~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = each.value.bypass_apps

    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }

  rules {
    deletion                = true
    update                  = each.value.target == "tag"
    non_fast_forward        = each.value.target == "branch"
    required_linear_history = each.value.target == "branch"

    dynamic "commit_message_pattern" {
      for_each = each.value.target == "branch" ? [1] : []

      content {
        name     = "Conventional commit, lowercase subject"
        operator = "regex"
        pattern  = "^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\\([a-z0-9._/-]+\\))?!?: [^A-Z\\n]+(\\n|$)"
      }
    }

    dynamic "pull_request" {
      for_each = each.value.target == "branch" ? [1] : []

      content {
        required_approving_review_count = 0
      }
    }
  }
}
