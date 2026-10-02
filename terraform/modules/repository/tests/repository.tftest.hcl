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
