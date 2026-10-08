mock_provider "github" {}

variables {
  config = "tests/fixtures/one-repository.yaml"
}

run "two_factor_required" {
  command = plan

  override_data {
    target = data.github_organization.organization
    values = {
      two_factor_requirement_enabled = true
    }
  }
}

run "two_factor_not_required" {
  command = plan

  override_data {
    target = data.github_organization.organization
    values = {
      two_factor_requirement_enabled = false
    }
  }

  expect_failures = [check.two_factor_requirement]
}
