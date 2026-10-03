mock_provider "github" {
  mock_data "github_repository" {
    defaults = {
      default_branch = "main"
    }
  }
}

run "test_yaml" {
  command = apply

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

  assert {
    condition     = keys(module.repository[".github"].environments) == ["production", "release"] && keys(module.repository["template"].environments) == ["release"] && length(module.repository["template-use"].environments) == 0
    error_message = "Expected .github production and release, template release, template-use none."
  }

  assert {
    condition     = length(module.repository[".github"].environments["production"].environment.deployment_branch_policy) == 1 && module.repository[".github"].environments["production"].deployment_policies["~DEFAULT_BRANCH"].branch_pattern == "main"
    error_message = "Unexpected .github production branch policy."
  }

  assert {
    condition     = module.repository["template"].environments["release"].deployment_policies["~DEFAULT_BRANCH"].branch_pattern == "main"
    error_message = "Unexpected template release branch policy."
  }

  assert {
    condition     = alltrue([for m in module.repository : keys(m.rulesets) == ["default-branch"] && [for a in m.rulesets["default-branch"].bypass_actors : a.actor_id] == [3144447]])
    error_message = "Expected the default-branch ruleset with the semantic-release App bypass in every repository."
  }
}
