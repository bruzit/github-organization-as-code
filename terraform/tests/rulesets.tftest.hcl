mock_provider "github" {
  mock_data "github_organization" {
    defaults = {
      two_factor_requirement_enabled = true
    }
  }
}

run "rulesets" {
  command = plan

  variables {
    config = "tests/fixtures/rulesets.yaml"
  }

  assert {
    condition     = keys(module.repository["inherit"].rulesets) == ["default-branch", "other"] && [for a in module.repository["inherit"].rulesets["default-branch"].bypass_actors : a.actor_id] == [3144447]
    error_message = "Expected inherited rulesets default-branch with the App bypass, and other."
  }

  assert {
    condition     = length(module.repository["override"].rulesets["default-branch"].bypass_actors) == 0
    error_message = "A repository ruleset must replace the organization one wholesale."
  }

  assert {
    condition     = keys(module.repository["opt-out"].rulesets) == ["other"]
    error_message = "Expected default-branch opted out."
  }

  assert {
    condition     = keys(module.repository["repository-only"].rulesets) == ["default-branch", "extra", "other"] && [for a in module.repository["repository-only"].rulesets["extra"].bypass_actors : a.actor_id] == [42]
    error_message = "Expected repository-only extra next to the organization rulesets."
  }
}

run "no_rulesets" {
  command = plan

  variables {
    config = "tests/fixtures/one-repository.yaml"
  }

  assert {
    condition     = length(module.repository["foo"].rulesets) == 0
    error_message = "Expected no rulesets."
  }
}

run "unknown_ruleset_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-ruleset-key.yaml"
  }

  expect_failures = [var.config]
}

run "unknown_organization_ruleset_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-organization-ruleset-key.yaml"
  }

  expect_failures = [var.config]
}

run "organization_ruleset_null" {
  command = plan

  variables {
    config = "tests/fixtures/organization-ruleset-null.yaml"
  }

  expect_failures = [var.config]
}
