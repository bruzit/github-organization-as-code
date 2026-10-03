mock_provider "github" {}

variables {
  repository     = "foo"
  default_branch = "trunk"
}

run "defaults" {
  command = plan

  variables {
    environment = {
      name = "release"
    }
  }

  assert {
    condition     = github_repository_environment.this.repository == "foo" && github_repository_environment.this.environment == "release"
    error_message = "Unexpected repository or environment."
  }

  assert {
    condition     = github_repository_environment.this.can_admins_bypass == false
    error_message = "Admins must not bypass environment protections."
  }

  assert {
    condition     = length(github_repository_environment.this.deployment_branch_policy) == 0
    error_message = "Unexpected deployment branch policy."
  }

  assert {
    condition     = length(github_repository_environment_deployment_policy.this) == 0
    error_message = "Unexpected deployment policies."
  }
}

run "deployment_branches" {
  command = plan

  variables {
    environment = {
      name                = "release"
      deployment_branches = ["main", "release/*"]
    }
  }

  assert {
    condition     = !github_repository_environment.this.deployment_branch_policy[0].protected_branches && github_repository_environment.this.deployment_branch_policy[0].custom_branch_policies
    error_message = "Expected custom branch policies only."
  }

  assert {
    condition     = keys(github_repository_environment_deployment_policy.this) == ["main", "release/*"]
    error_message = "Expected one deployment policy per pattern."
  }

  assert {
    condition     = alltrue([for p in github_repository_environment_deployment_policy.this : p.repository == "foo" && p.environment == "release" && p.tag_pattern == null])
    error_message = "Unexpected deployment policy repository, environment or tag pattern."
  }

  assert {
    condition     = github_repository_environment_deployment_policy.this["release/*"].branch_pattern == "release/*"
    error_message = "Unexpected branch pattern."
  }
}

run "default_branch_token" {
  command = plan

  variables {
    environment = {
      name                = "release"
      deployment_branches = ["~DEFAULT_BRANCH", "main"]
    }
  }

  assert {
    condition     = github_repository_environment_deployment_policy.this["~DEFAULT_BRANCH"].branch_pattern == "trunk" && github_repository_environment_deployment_policy.this["main"].branch_pattern == "main"
    error_message = "~DEFAULT_BRANCH must resolve to the default branch."
  }
}

run "default_branch_token_duplicate" {
  command = plan

  variables {
    environment = {
      name                = "release"
      deployment_branches = ["~DEFAULT_BRANCH", "trunk"]
    }
  }

  expect_failures = [var.environment]
}

run "deployment_branches_empty" {
  command = plan

  variables {
    environment = {
      name                = "release"
      deployment_branches = []
    }
  }

  expect_failures = [var.environment]
}

run "deployment_branches_duplicate" {
  command = plan

  variables {
    environment = {
      name                = "release"
      deployment_branches = ["main", "main"]
    }
  }

  expect_failures = [var.environment]
}

run "name_empty" {
  command = plan

  variables {
    environment = {
      name = " "
    }
  }

  expect_failures = [var.environment]
}
