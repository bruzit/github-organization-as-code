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

run "variables_secrets" {
  command = apply

  variables {
    environment = {
      name      = "release"
      variables = { APP_ID = "3144447", _example = "example" }
      secrets   = ["APP_PEM_FILE"]
    }
  }

  assert {
    condition     = { for k, v in github_actions_environment_variable.this : k => [v.repository, v.environment, v.variable_name, v.value] } == { APP_ID = ["foo", "release", "APP_ID", "3144447"], _example = ["foo", "release", "_example", "example"] }
    error_message = "Unexpected environment variables."
  }

  assert {
    condition     = keys(github_actions_environment_secret.this) == ["APP_PEM_FILE"] && github_actions_environment_secret.this["APP_PEM_FILE"].repository == "foo" && github_actions_environment_secret.this["APP_PEM_FILE"].environment == "release"
    error_message = "Unexpected environment secrets."
  }

  assert {
    condition     = nonsensitive(github_actions_environment_secret.this["APP_PEM_FILE"].value) == "set-by-hand" && github_actions_environment_secret.this["APP_PEM_FILE"].value_encrypted == null && github_actions_environment_secret.this["APP_PEM_FILE"].plaintext_value == null
    error_message = "Secrets must be created with the set-by-hand placeholder only."
  }
}

run "variables_secrets_default" {
  command = plan

  variables {
    environment = {
      name      = "release"
      variables = null
      secrets   = null
    }
  }

  assert {
    condition     = length(github_actions_environment_variable.this) == 0 && length(github_actions_environment_secret.this) == 0
    error_message = "Expected no variables or secrets."
  }
}

run "name_invalid" {
  command = plan

  variables {
    environment = {
      name      = "release"
      variables = { "1APP" = "x" }
    }
  }

  expect_failures = [var.environment]
}

run "name_github_prefix" {
  command = plan

  variables {
    environment = {
      name    = "release"
      secrets = ["github_token"]
    }
  }

  expect_failures = [var.environment]
}

run "name_hyphen" {
  command = plan

  variables {
    environment = {
      name    = "release"
      secrets = ["APP-PEM"]
    }
  }

  expect_failures = [var.environment]
}

run "variables_duplicate_case" {
  command = plan

  variables {
    environment = {
      name      = "release"
      variables = { APP_ID = "1", app_id = "2" }
    }
  }

  expect_failures = [var.environment]
}

run "secrets_duplicate_case" {
  command = plan

  variables {
    environment = {
      name    = "release"
      secrets = ["APP_PEM_FILE", "app_pem_file"]
    }
  }

  expect_failures = [var.environment]
}
