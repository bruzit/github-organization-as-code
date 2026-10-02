mock_provider "github" {}

override_resource {
  target = module.repository[".github"].github_repository.this
  values = {
    id = ".github"
  }
}

override_resource {
  target = module.repository["template"].github_repository.this
  values = {
    id = "template"
  }
}

override_resource {
  target = module.repository["template-use"].github_repository.this
  values = {
    id = "template-use"
  }
}

run "test_yaml" {
  command = plan

  variables {
    config = "../test.yaml"
  }

  assert {
    condition     = keys(module.repository) == [".github", "template", "template-use"]
    error_message = "Expected repositories .github, template, template-use."
  }

  assert {
    condition     = startswith(module.repository[".github"].repository.description, "BruzIT Test organization profile")
    error_message = "Unexpected .github description."
  }

  assert {
    condition     = contains(module.repository[".github"].repository.topics, "terraform") && length(module.repository[".github"].repository.topics) == 10
    error_message = "Unexpected .github topics."
  }

  assert {
    condition     = module.repository["template"].repository.is_template && module.repository["template"].repository.topics == toset(["repository-template"])
    error_message = "Unexpected template is_template or topics."
  }

  assert {
    condition     = module.repository["template-use"].repository.template[0].owner == "bruzit-test" && module.repository["template-use"].repository.template[0].repository == "template" && !module.repository["template-use"].repository.template[0].include_all_branches
    error_message = "Unexpected template-use template."
  }

  assert {
    condition     = alltrue([for m in module.repository : m.repository.archive_on_destroy && m.repository.delete_branch_on_merge])
    error_message = "Every repository must archive on destroy and delete branches on merge."
  }
}

run "test_yaml_import" {
  command = plan

  variables {
    config = "../test.yaml"
  }

  assert {
    condition     = alltrue([for k, m in module.repository : m.repository.id == k])
    error_message = "Every repository must be imported, not created."
  }
}
