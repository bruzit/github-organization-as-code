mock_provider "github" {}

override_resource {
  target = module.repository["bar"].github_repository.this
  values = {
    id = "bar"
  }
}

override_resource {
  target = module.repository["baz"].github_repository.this
  values = {
    id = "baz"
  }
}

override_resource {
  target = module.repository["foo"].github_repository.this
  values = {
    id = "foo"
  }
}

run "repositories_missing" {
  command = plan

  variables {
    config = "tests/fixtures/repositories-missing.yaml"
  }

  expect_failures = [var.config]
}

run "repositories_null" {
  command = plan

  variables {
    config = "tests/fixtures/repositories-null.yaml"
  }

  expect_failures = [var.config]
}

run "repositories_empty" {
  command = plan

  variables {
    config = "tests/fixtures/repositories-empty.yaml"
  }

  expect_failures = [var.config]
}

run "repositories_map" {
  command = plan

  variables {
    config = "tests/fixtures/repositories-map.yaml"
  }

  expect_failures = [var.config]
}

run "repositories_string" {
  command = plan

  variables {
    config = "tests/fixtures/repositories-string.yaml"
  }

  expect_failures = [var.config]
}

run "repository_not_a_map" {
  command = plan

  variables {
    config = "tests/fixtures/repository-not-a-map.yaml"
  }

  expect_failures = [var.config]
}

run "repository_without_name" {
  command = plan

  variables {
    config = "tests/fixtures/repository-without-name.yaml"
  }

  expect_failures = [var.config]
}

run "duplicate_name" {
  command = plan

  variables {
    config = "tests/fixtures/duplicate-name.yaml"
  }

  expect_failures = [var.config]
}

run "duplicate_name_case" {
  command = plan

  variables {
    config = "tests/fixtures/duplicate-name-case.yaml"
  }

  expect_failures = [var.config]
}

run "unknown_repository_key" {
  command = plan

  variables {
    config = "tests/fixtures/unknown-repository-key.yaml"
  }

  expect_failures = [var.config]
}

run "one_repository" {
  command = plan

  variables {
    config = "tests/fixtures/one-repository.yaml"
  }

  assert {
    condition     = keys(module.repository) == ["foo"]
    error_message = "Expected repository foo."
  }
}

run "several_repositories" {
  command = plan

  variables {
    config = "tests/fixtures/several-repositories.yaml"
  }

  assert {
    condition     = keys(module.repository) == ["bar", "baz", "foo"]
    error_message = "Expected repositories bar, baz, foo."
  }
}
