mock_provider "github" {
  mock_data "github_repository" {
    defaults = {
      default_branch = "trunk"
    }
  }
}

run "environments" {
  command = apply

  variables {
    config = "tests/fixtures/environments.yaml"
  }

  assert {
    condition     = keys(module.repository["inherit"].environments) == ["release", "staging"]
    error_message = "Expected inherited environments release, staging."
  }

  assert {
    condition     = module.repository["inherit"].environments["release"].deployment_policies["~DEFAULT_BRANCH"].branch_pattern == "trunk" && length(module.repository["inherit"].environments["staging"].deployment_policies) == 0
    error_message = "Unexpected inherited environment settings."
  }

  assert {
    condition     = length(module.repository["override"].environments["release"].deployment_policies) == 0 && length(module.repository["override"].environments["release"].environment.deployment_branch_policy) == 0
    error_message = "A repository environment must replace the organization one wholesale."
  }

  assert {
    condition     = keys(module.repository["opt-out"].environments) == ["staging"]
    error_message = "Expected release opted out."
  }

  assert {
    condition     = keys(module.repository["repository-only"].environments) == ["production", "release", "staging"]
    error_message = "Expected repository-only production next to the organization environments."
  }

  assert {
    condition     = module.repository["repository-only"].environments["production"].environment.environment == "production" && module.repository["repository-only"].environments["production"].environment.repository == "repository-only"
    error_message = "Unexpected repository-only environment."
  }
}

run "no_environments" {
  command = plan

  variables {
    config = "tests/fixtures/one-repository.yaml"
  }

  assert {
    condition     = length(module.repository["foo"].environments) == 0
    error_message = "Expected no environments."
  }
}

run "unknown_environment_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-environment-key.yaml"
  }

  expect_failures = [var.config]
}

run "unknown_organization_environment_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-organization-environment-key.yaml"
  }

  expect_failures = [var.config]
}

run "organization_environment_null" {
  command = plan

  variables {
    config = "tests/fixtures/organization-environment-null.yaml"
  }

  expect_failures = [var.config]
}

run "environments_list" {
  command = plan

  variables {
    config = "tests/fixtures/environments-list.yaml"
  }

  expect_failures = [var.config]
}

run "unknown_organization_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-organization-key.yaml"
  }

  expect_failures = [var.config]
}
