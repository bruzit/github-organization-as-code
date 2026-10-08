mock_provider "github" {
  mock_data "github_organization" {
    defaults = {
      two_factor_requirement_enabled = true
    }
  }
}

run "missing" {
  command = plan

  variables {
    config = "tests/fixtures/missing.yaml"
  }

  expect_failures = [var.config]
}

run "empty" {
  command = plan

  variables {
    config = "tests/fixtures/empty.yaml"
  }

  expect_failures = [var.config]
}

run "comments_only" {
  command = plan

  variables {
    config = "tests/fixtures/comments-only.yaml"
  }

  expect_failures = [var.config]
}

run "document_start_only" {
  command = plan

  variables {
    config = "tests/fixtures/document-start-only.yaml"
  }

  expect_failures = [var.config]
}

run "invalid" {
  command = plan

  variables {
    config = "tests/fixtures/invalid.yaml"
  }

  expect_failures = [var.config]
}

run "top_level_list" {
  command = plan

  variables {
    config = "tests/fixtures/top-level-list.yaml"
  }

  expect_failures = [var.config]
}

run "unknown_top_level_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-top-level-key.yaml"
  }

  expect_failures = [var.config]
}

run "unknown_top_level_key_no_repositories" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-top-level-key-no-repositories.yaml"
  }

  expect_failures = [var.config]
}
