mock_provider "github" {}

run "name_only" {
  command = plan

  variables {
    repository = {
      name = "foo"
    }
  }

  assert {
    condition     = github_repository.this.name == "foo"
    error_message = "Unexpected name."
  }

  assert {
    condition     = github_repository.this.description == null && github_repository.this.homepage_url == null && github_repository.this.is_template == null
    error_message = "Unset optional attributes must be null."
  }

  assert {
    condition     = length(github_repository.this.template) == 0
    error_message = "Unexpected template block."
  }

  assert {
    condition     = github_repository.this.archive_on_destroy
    error_message = "Repository must archive on destroy."
  }

  assert {
    condition     = github_repository.this.delete_branch_on_merge
    error_message = "Repository must delete branches on merge."
  }

  assert {
    condition     = github_repository.this.security_and_analysis[0].secret_scanning[0].status == "enabled"
    error_message = "Repository must enable secret scanning."
  }

  assert {
    condition     = github_repository.this.security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    error_message = "Repository must enable secret scanning push protection."
  }
}

run "name_leading_dot" {
  command = plan

  variables {
    repository = {
      name = ".github"
    }
  }

  assert {
    condition     = github_repository.this.name == ".github"
    error_message = "Unexpected name."
  }
}

run "name_max_length" {
  command = plan

  variables {
    repository = {
      name = "${join("", [for i in range(100) : "a"])}"
    }
  }

  assert {
    condition     = length(github_repository.this.name) == 100
    error_message = "Unexpected name."
  }
}

run "name_empty" {
  command = plan

  variables {
    repository = {
      name = ""
    }
  }

  expect_failures = [var.repository]
}

run "name_dot" {
  command = plan

  variables {
    repository = {
      name = "."
    }
  }

  expect_failures = [var.repository]
}

run "name_dot_dot" {
  command = plan

  variables {
    repository = {
      name = ".."
    }
  }

  expect_failures = [var.repository]
}

run "name_space" {
  command = plan

  variables {
    repository = {
      name = "foo bar"
    }
  }

  expect_failures = [var.repository]
}

run "name_slash" {
  command = plan

  variables {
    repository = {
      name = "foo/bar"
    }
  }

  expect_failures = [var.repository]
}

run "name_too_long" {
  command = plan

  variables {
    repository = {
      name = "${join("", [for i in range(101) : "a"])}"
    }
  }

  expect_failures = [var.repository]
}

run "description" {
  command = plan

  variables {
    repository = {
      name        = "foo"
      description = "Foo bar."
    }
  }

  assert {
    condition     = github_repository.this.description == "Foo bar."
    error_message = "Unexpected description."
  }
}

run "homepage_url_https" {
  command = plan

  variables {
    repository = {
      name         = "foo"
      homepage_url = "https://example.com"
    }
  }

  assert {
    condition     = github_repository.this.homepage_url == "https://example.com"
    error_message = "Unexpected homepage_url."
  }
}

run "homepage_url_http" {
  command = plan

  variables {
    repository = {
      name         = "foo"
      homepage_url = "http://example.com"
    }
  }

  assert {
    condition     = github_repository.this.homepage_url == "http://example.com"
    error_message = "Unexpected homepage_url."
  }
}

run "homepage_url_empty" {
  command = plan

  variables {
    repository = {
      name         = "foo"
      homepage_url = ""
    }
  }

  assert {
    condition     = github_repository.this.homepage_url == ""
    error_message = "Unexpected homepage_url."
  }
}

run "homepage_url_no_scheme" {
  command = plan

  variables {
    repository = {
      name         = "foo"
      homepage_url = "example.com"
    }
  }

  expect_failures = [var.repository]
}

run "homepage_url_ftp" {
  command = plan

  variables {
    repository = {
      name         = "foo"
      homepage_url = "ftp://example.com"
    }
  }

  expect_failures = [var.repository]
}

run "topics" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = ["terraform", "github-organization", "c3po"]
    }
  }

  assert {
    condition     = github_repository.this.topics == toset(["terraform", "github-organization", "c3po"])
    error_message = "Unexpected topics."
  }
}

run "topics_empty" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = []
    }
  }

  assert {
    condition     = length(github_repository.this.topics) == 0
    error_message = "Unexpected topics."
  }
}

run "topics_max" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = [for i in range(20) : "topic-${i}"]
    }
  }

  assert {
    condition     = length(github_repository.this.topics) == 20
    error_message = "Unexpected topics."
  }
}

run "topic_max_length" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = [join("", [for i in range(50) : "a"])]
    }
  }

  assert {
    condition     = length(github_repository.this.topics) == 1
    error_message = "Unexpected topics."
  }
}

run "topics_uppercase" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = ["Terraform"]
    }
  }

  expect_failures = [var.repository]
}

run "topics_leading_hyphen" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = ["-terraform"]
    }
  }

  expect_failures = [var.repository]
}

run "topics_underscore" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = ["terraform_github"]
    }
  }

  expect_failures = [var.repository]
}

run "topics_empty_string" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = [""]
    }
  }

  expect_failures = [var.repository]
}

run "topics_too_long" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = [join("", [for i in range(51) : "a"])]
    }
  }

  expect_failures = [var.repository]
}

run "topics_too_many" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = [for i in range(21) : "topic-${i}"]
    }
  }

  expect_failures = [var.repository]
}

run "topics_duplicate" {
  command = plan

  variables {
    repository = {
      name   = "foo"
      topics = ["terraform", "iac", "terraform"]
    }
  }

  expect_failures = [var.repository]
}

run "is_template_true" {
  command = plan

  variables {
    repository = {
      name        = "foo"
      is_template = true
    }
  }

  assert {
    condition     = github_repository.this.is_template == true
    error_message = "Unexpected is_template."
  }
}

run "is_template_false" {
  command = plan

  variables {
    repository = {
      name        = "foo"
      is_template = false
    }
  }

  assert {
    condition     = github_repository.this.is_template == false
    error_message = "Unexpected is_template."
  }
}

run "template" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      template = { owner = "bruzit", repository = "template" }
    }
  }

  assert {
    condition     = length(github_repository.this.template) == 1
    error_message = "Expected one template block."
  }

  assert {
    condition     = github_repository.this.template[0].owner == "bruzit" && github_repository.this.template[0].repository == "template"
    error_message = "Unexpected template."
  }

  assert {
    condition     = !github_repository.this.template[0].include_all_branches
    error_message = "include_all_branches must default to false."
  }
}

run "template_include_all_branches" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      template = { owner = "bruzit", repository = "template", include_all_branches = true }
    }
  }

  assert {
    condition     = github_repository.this.template[0].include_all_branches
    error_message = "Unexpected include_all_branches."
  }
}

run "template_owner_empty" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      template = { owner = "", repository = "template" }
    }
  }

  expect_failures = [var.repository]
}

run "template_repository_empty" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      template = { owner = "bruzit", repository = " " }
    }
  }

  expect_failures = [var.repository]
}

run "rulesets_none" {
  command = plan

  variables {
    repository = {
      name = "foo"
    }
  }

  assert {
    condition     = length(github_repository_ruleset.this) == 0
    error_message = "Expected no rulesets."
  }
}

run "ruleset" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = { bypass_apps = [3144447, 42] } }
    }
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].repository == "foo" && github_repository_ruleset.this["default-branch"].name == "default-branch"
    error_message = "Unexpected repository or ruleset name."
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].target == "branch" && github_repository_ruleset.this["default-branch"].enforcement == "active"
    error_message = "Expected an active branch ruleset."
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].conditions[0].ref_name[0].include == tolist(["~DEFAULT_BRANCH"]) && length(github_repository_ruleset.this["default-branch"].conditions[0].ref_name[0].exclude) == 0
    error_message = "Expected the default branch only."
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].rules[0].deletion && github_repository_ruleset.this["default-branch"].rules[0].non_fast_forward
    error_message = "Expected deletion and force push blocked."
  }

  assert {
    condition     = !github_repository_ruleset.this["default-branch"].rules[0].update
    error_message = "Expected branch updates allowed."
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].rules[0].required_linear_history
    error_message = "Expected linear history required."
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].rules[0].commit_message_pattern[0].operator == "regex" && startswith(github_repository_ruleset.this["default-branch"].rules[0].commit_message_pattern[0].pattern, "^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)")
    error_message = "Expected a conventional commit message pattern."
  }

  assert {
    condition     = github_repository_ruleset.this["default-branch"].rules[0].pull_request[0].required_approving_review_count == 0 && length(github_repository_ruleset.this["default-branch"].rules[0].required_status_checks) == 0
    error_message = "Expected a pull request with no approvals and no status checks."
  }

  assert {
    condition     = [for a in github_repository_ruleset.this["default-branch"].bypass_actors : a.actor_id] == [3144447, 42] && alltrue([for a in github_repository_ruleset.this["default-branch"].bypass_actors : a.actor_type == "Integration" && a.bypass_mode == "always"])
    error_message = "Expected the Apps to always bypass."
  }
}

run "ruleset_tag" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { release-tags = { target = "tag" } }
    }
  }

  assert {
    condition     = github_repository_ruleset.this["release-tags"].target == "tag" && github_repository_ruleset.this["release-tags"].enforcement == "active"
    error_message = "Expected an active tag ruleset."
  }

  assert {
    condition     = github_repository_ruleset.this["release-tags"].conditions[0].ref_name[0].include == tolist(["refs/tags/v*.*.*"]) && length(github_repository_ruleset.this["release-tags"].conditions[0].ref_name[0].exclude) == 0
    error_message = "Expected release tags vX.Y.Z only."
  }

  assert {
    condition     = github_repository_ruleset.this["release-tags"].rules[0].update && github_repository_ruleset.this["release-tags"].rules[0].deletion && github_repository_ruleset.this["release-tags"].rules[0].creation != true
    error_message = "Expected update and deletion blocked, creation allowed."
  }

  assert {
    condition     = !github_repository_ruleset.this["release-tags"].rules[0].non_fast_forward && !github_repository_ruleset.this["release-tags"].rules[0].required_linear_history && length(github_repository_ruleset.this["release-tags"].rules[0].commit_message_pattern) == 0 && length(github_repository_ruleset.this["release-tags"].rules[0].pull_request) == 0
    error_message = "Expected no branch rules."
  }

  assert {
    condition     = length(github_repository_ruleset.this["release-tags"].bypass_actors) == 0
    error_message = "Expected no bypass actors."
  }
}

run "ruleset_target_invalid" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = { target = "push" } }
    }
  }

  expect_failures = [var.repository]
}

run "ruleset_bypass_apps_absent" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = {} }
    }
  }

  assert {
    condition     = length(github_repository_ruleset.this["default-branch"].bypass_actors) == 0
    error_message = "Expected no bypass actors."
  }
}

run "ruleset_bypass_apps_empty" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = { bypass_apps = [] } }
    }
  }

  assert {
    condition     = length(github_repository_ruleset.this["default-branch"].bypass_actors) == 0
    error_message = "Expected no bypass actors."
  }
}

run "ruleset_bypass_apps_fraction" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = { bypass_apps = [1.5] } }
    }
  }

  expect_failures = [var.repository]
}

run "ruleset_bypass_apps_zero" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = { bypass_apps = [0] } }
    }
  }

  expect_failures = [var.repository]
}

run "ruleset_bypass_apps_duplicate" {
  command = plan

  variables {
    repository = {
      name     = "foo"
      rulesets = { default-branch = { bypass_apps = [42, 42] } }
    }
  }

  expect_failures = [var.repository]
}
