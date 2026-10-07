mock_provider "github" {}

override_resource {
  target = github_membership.admin
}

run "members" {
  command = plan

  variables {
    config = "tests/fixtures/members.yaml"
  }

  assert {
    condition     = keys(github_membership.admin) == ["bruzina", "octocat"] && alltrue([for m in github_membership.admin : m.role == "admin"])
    error_message = "Expected admins bruzina and octocat."
  }
}

run "no_members" {
  command = plan

  variables {
    config = "tests/fixtures/one-repository.yaml"
  }

  assert {
    condition     = length(github_membership.admin) == 0
    error_message = "Expected no memberships."
  }
}

run "members_null" {
  command = plan

  variables {
    config = "tests/fixtures/members-null.yaml"
  }

  assert {
    condition     = length(github_membership.admin) == 0
    error_message = "Expected no memberships."
  }
}

run "members_unknown_key" {
  command = plan

  variables {
    config = "tests/fixtures/members-unknown-key.yaml"
  }

  expect_failures = [var.config]
}

run "members_admins_empty" {
  command = plan

  variables {
    config = "tests/fixtures/members-admins-empty.yaml"
  }

  expect_failures = [var.config]
}

run "members_admins_map" {
  command = plan

  variables {
    config = "tests/fixtures/members-admins-map.yaml"
  }

  expect_failures = [var.config]
}

run "members_admins_blank" {
  command = plan

  variables {
    config = "tests/fixtures/members-admins-blank.yaml"
  }

  expect_failures = [var.config]
}

run "members_admins_duplicate_case" {
  command = plan

  variables {
    config = "tests/fixtures/members-admins-duplicate-case.yaml"
  }

  expect_failures = [var.config]
}
