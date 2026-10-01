mock_provider "github" {}

run "test_yaml" {
  command = plan

  variables {
    config = "../test.yaml"
  }

  assert {
    condition     = keys(github_repository.this) == [".github", "template", "template-use"]
    error_message = "Expected repositories .github, template, template-use."
  }

  assert {
    condition     = startswith(github_repository.this[".github"].description, "BruzIT Test organization profile")
    error_message = "Unexpected .github description."
  }

  assert {
    condition     = contains(github_repository.this[".github"].topics, "terraform") && length(github_repository.this[".github"].topics) == 10
    error_message = "Unexpected .github topics."
  }

  assert {
    condition     = github_repository.this["template"].is_template && github_repository.this["template"].topics == toset(["repository-template"])
    error_message = "Unexpected template is_template or topics."
  }

  assert {
    condition     = github_repository.this["template-use"].template[0].owner == "bruzit-test" && github_repository.this["template-use"].template[0].repository == "template" && !github_repository.this["template-use"].template[0].include_all_branches
    error_message = "Unexpected template-use template."
  }

  assert {
    condition     = alltrue([for r in github_repository.this : r.archive_on_destroy && r.delete_branch_on_merge])
    error_message = "Every repository must archive on destroy and delete branches on merge."
  }
}
