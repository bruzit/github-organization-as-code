# GitHub Organization as Code

[![License](https://img.shields.io/github/license/bruzit/github-organization-as-code)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/bruzit/github-organization-as-code)](https://github.com/bruzit/github-organization-as-code/commits)
[![MegaLinter](https://github.com/bruzit/github-organization-as-code/actions/workflows/megalinter.yaml/badge.svg)](https://github.com/bruzit/github-organization-as-code/actions/workflows/megalinter.yaml)
[![Terraform Test](https://github.com/bruzit/github-organization-as-code/actions/workflows/terraform-test.yaml/badge.svg)](https://github.com/bruzit/github-organization-as-code/actions/workflows/terraform-test.yaml)
[![Terraform Plan](https://github.com/bruzit/github-organization-as-code/actions/workflows/terraform-plan.yaml/badge.svg)](https://github.com/bruzit/github-organization-as-code/actions/workflows/terraform-plan.yaml)
[![Semantic Release](https://github.com/bruzit/github-organization-as-code/actions/workflows/semantic-release.yaml/badge.svg)](https://github.com/bruzit/github-organization-as-code/actions/workflows/semantic-release.yaml)
[![Test](https://github.com/bruzit/github-organization-as-code/actions/workflows/test.yaml/badge.svg)](https://github.com/bruzit/github-organization-as-code/actions/workflows/test.yaml)

GitOps workflow turning a declarative YAML organization definition into GitHub resources with Terraform, authenticated by a GitHub App.

## Features

- Declarative YAML definition of organization owners and repositories: metadata, template, environments with variables and secret placeholders, rulesets; organization-wide environments and rulesets with per-repository overrides.
- Repository defaults: archive on removal, branch cleanup, rebase and squash merges only, issues, secret scanning.
- Composite action [`action.yaml`](action.yaml): apply on the default branch, plan on pull requests with read-only credentials.
- Terraform state in an S3-compatible bucket, e.g. Cloudflare R2, one workspace per organization.
- GitHub App authentication.

## Requirements

- Platform: GitHub Actions, GitHub organization; on the GitHub Free plan, rulesets and secret scanning work in public repositories only.
- S3-compatible storage with conditional writes.
- Local use: Terraform `~> 1.15`; direnv optional.

## Installation and Setup

1. Create the state bucket: [Terraform State Backend](#terraform-state-backend).
2. Create and install the GitHub Apps: [GitHub App](#github-app).
3. Write the configuration file: [Configuration File](#configuration-file).
4. Add the workflow, environments, variables and secrets: [Use Terraform Action](#use-terraform-action).

### Terraform State Backend

The S3 backend ([`terraform/config.tf`](terraform/config.tf)) works with any S3-compatible storage; BruzIT uses Cloudflare R2 with the bucket `bruzit-terraform-github`. The action passes the bucket at init (`-backend-config="bucket=..."` from `aws-bucket`) and the endpoint as `AWS_ENDPOINT_URL_S3` (from `aws-endpoint-url-s3`, e.g. `https://ACCOUNT_ID.r2.cloudflarestorage.com`). `skip_credentials_validation` and `skip_requesting_account_id` skip the AWS STS and IAM calls non-AWS storage does not serve; `use_lockfile` locks the state with a lock object in the bucket, which needs conditional writes.

Each organization has its own Terraform workspace, `TF_WORKSPACE` set to `owner`, so several organizations share one bucket with separate states.

### GitHub App

To create a GitHub App and a GitHub App Installation:

- GitHub / _Organization_ / Settings / Developer settings / GitHub Apps
  - **New GitHub App**
    - Create GitHub App
      - GitHub App name: _name_
      - Description: _description_
      - Homepage URL: _homepage URL_
    - Webhook
      - Active: off
    - Permissions
      - Repository permissions
        - Administration: Read and write
        - Environments: Read and write
        - Secrets: Read and write
        - Variables: Read and write
      - Organization permissions
        - Administration: Read and write
        - Members: Read and write
      - Where can this GitHub App be installed?: _choose what suits you best_
    - **Create GitHub App**
  - _your app_
    - General
      - **Generate a private key**
    - Install App
      - _your organization_: **Install**

Create a second App, same permissions read-only, for the `plan` environment.

### Configuration File

Minimal `config.yaml`; full schema in [GitHub Organization Configuration YAML](#github-organization-configuration-yaml):

```yaml
---
repositories:
  - name: .github
    visibility: public
```

### Use Terraform Action

Create a workflow, for example, `.github/workflows/github-organization-as-code.yaml`:

```yaml
---
name: GitHub Organization as Code

on:
  push:
    branches:
      - main

concurrency:
  group: ${{ github.workflow }}

jobs:
  terraform:
    name: Terraform
    environment: production
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          persist-credentials: false
      - name: Terraform
        uses: bruzit/github-organization-as-code@v0
        with:
          path: config.yaml
          owner: ${{ vars.GH_TF_OWNER }}
          app-id: ${{ vars.GH_TF_APP_ID }}
          app-installation-id: ${{ vars.GH_TF_APP_INSTALLATION_ID }}
          app-pem-file: ${{ secrets.GH_TF_APP_PEM_FILE }}
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-bucket: ${{ vars.AWS_TF_BUCKET }}
          aws-endpoint-url-s3: ${{ vars.AWS_ENDPOINT_URL_S3 }}
```

The action ([`action.yaml`](action.yaml)) runs the Terraform code shipped with the action against the configuration file at `path`, relative to the workspace, so the caller checks out its repository first. It sets up the latest Terraform, checks formatting, initializes the S3 backend in `aws-bucket`, selects the workspace named after `owner`, validates, and applies with `-auto-approve`. `concurrency` queues pushes instead of failing the apply on the state lock.

`mode: plan` runs `terraform plan -lock=false -refresh=false` instead of the apply, for pull requests with read-only credentials (a read-only S3 key cannot write the state lock); no refresh, it compares against the last applied state. The plan goes to the job summary, truncated to 1 MB. Run it on `pull_request` with `environment: plan`.

CI credentials live in GitHub environment variables and secrets, not repository ones, one environment per mode with the same names:

| Name                        | Kind     | Local equivalent                    |
|-----------------------------|----------|-------------------------------------|
| `GH_TF_OWNER`               | variable | `GITHUB_OWNER`                      |
| `GH_TF_APP_ID`              | variable | `GITHUB_APP_ID`                     |
| `GH_TF_APP_INSTALLATION_ID` | variable | `GITHUB_APP_INSTALLATION_ID`        |
| `AWS_TF_BUCKET`             | variable | `AWS_BUCKET`                        |
| `AWS_ENDPOINT_URL_S3`       | variable | `AWS_ENDPOINT_URL_S3`               |
| `GH_TF_APP_PEM_FILE`        | secret   | `GITHUB_APP_PEM_FILE_PATH` contents |
| `AWS_ACCESS_KEY_ID`         | secret   | `AWS_ACCESS_KEY_ID`                 |
| `AWS_SECRET_ACCESS_KEY`     | secret   | `AWS_SECRET_ACCESS_KEY`             |

- Apply environment, e.g. `production` (`test` against `bruzit-test` in this repository): read-write App and S3 key, `deployment_branches` limited to `~DEFAULT_BRANCH`, so only the default branch can apply.
- `plan` environment: a separate read-only App and a read-only S3 key, no branch limit, so pull request branches can plan.

Declare the environments in the configuration file like any other, see [Environments](#environments), and set the secret values by hand.

## Usage

### GitHub Organization Configuration YAML

Create the configuration file:

```yaml
---
organization: # OPTIONAL
  members: # OPTIONAL, DEFAULT none
    admins: # REQUIRED; GitHub usernames
      - octocat
  environments: # OPTIONAL, DEFAULT none; added to every repository
    release:
      deployment_branches: # OPTIONAL, DEFAULT every branch
        - ~DEFAULT_BRANCH
      variables: # OPTIONAL, DEFAULT none
        APP_ID: "123456"
      secrets: # OPTIONAL, DEFAULT none; names only
        - APP_PEM_FILE
  rulesets: # OPTIONAL, DEFAULT none; added to every repository
    default-branch:
      target: branch # OPTIONAL, DEFAULT branch; branch or tag
      bypass_apps: # OPTIONAL, DEFAULT none
        - 123456
    release-tags:
      target: tag
repositories:
  - name: repo-slug
  # Metadata
    description: "The repository description." # OPTIONAL, DEFAULT none
    homepage_url: https://example.com/ # OPTIONAL, DEFAULT none
    topics: # OPTIONAL, DEFAULT none
      - some-topic
      - another-topic
    # Properties
    is_template: true # OPTIONAL, DEFAULT false
    visibility: private # REQUIRED; public or private
    # Contents
    template: # OPTIONAL, DEFAULT none
      owner: bruzit
      repository: template
      include_all_branches: true # OPTIONAL, DEFAULT false
    # Environments
    environments: # OPTIONAL, DEFAULT none
      release: ~ # opts out of the organization environment
      production:
        deployment_branches: # OPTIONAL, DEFAULT every branch
          - ~DEFAULT_BRANCH
          - release/*
        reviewers: [octocat] # OPTIONAL, DEFAULT none; GitHub usernames, any one approves, self-review allowed
    # Rulesets
    rulesets: # OPTIONAL, DEFAULT none
      default-branch: ~ # opts out of the organization ruleset
    required_checks: # OPTIONAL, DEFAULT none; GitHub Actions job names required by every branch ruleset
      - Required (MegaLinter)
```

### Members

`organization.members.admins` lists the organization owners. Only owners are managed: other members, teams and outside collaborators stay unmanaged. A listed user who is not a member yet is invited and stays pending until they accept. Every owner has `prevent_destroy`, so removing one from the list fails the plan; demote or remove an owner explicitly (`removed` block or `terraform state rm`).

Members need the App's organization Members permission, see [GitHub App](#github-app).

Require two-factor authentication by hand in _Organization_ / Settings / Authentication security (neither the API nor the Terraform provider can set it); plans warn while it is not required.

### Templates

`template` creates the repository from the template repository `OWNER/REPOSITORY` (`owner`, `repository`), which needs `is_template: true`: its default branch only, every branch with `include_all_branches: true`. It applies at creation only; adding or changing it on an existing repository does not touch its contents.

### Environments

`organization.environments` is added to every repository's `environments`. A repository environment of the same name replaces the organization one wholesale (no key-level merge), `~` opts the repository out of it, other names are repository-only.

`deployment_branches` limits deployments to branches matching the name patterns; without it every branch can deploy. `~DEFAULT_BRANCH` stands for the repository's default branch, resolved by Terraform (GitHub deployment branch policies have no such token). `reviewers` requires one of the listed users to approve a job targeting the environment (self-review allowed, for a single maintainer); without it the job runs without an approval step. No wait timer. Repository admins cannot bypass environment protection rules.

`variables` maps variable names to values, managed by Terraform: a value changed by hand is reverted on the next apply.

`secrets` lists secret names only; values never come from the YAML. Terraform creates each secret with the placeholder value `set-by-hand` and never updates it, so set the real value by hand, before any job uses the environment:

```shell
gh secret set NAME --env ENVIRONMENT --repo OWNER/REPOSITORY
```

Variable and secret names: A-Z, a-z, 0-9, `_`, not starting with a digit or `GITHUB_`, unique per environment case-insensitively. A job sees them only with `environment: ENVIRONMENT`; they take precedence over repository and organization variables and secrets of the same name.

Environments need the App's repository Administration permission, variables and secrets its Environments, Variables and Secrets permissions, see [GitHub App](#github-app).

### Rulesets

`organization.rulesets` is added to every repository's `rulesets`, with the same replace, `~` opt-out and repository-only semantics as [environments](#environments).

A `branch` ruleset (default `target`) protects the repository's default branch: changes only through a pull request (no approval required, so a single maintainer can merge their own), no force pushes, no deletion, linear history, [Conventional Commits 1.0.0 specification](https://www.conventionalcommits.org/en/v1.0.0/) messages with a lowercase subject, and the repository's `required_checks` passing on the latest code.

A `tag` ruleset protects release tags `vX.Y.Z` (`refs/tags/v*.*.*`): no update, no deletion; creation stays allowed, e.g. for semantic-release. Major tags `vN` do not match, so a release App can still move them.

On the GitHub Free plan, rulesets are available in public repositories only.

`required_checks` lists check run names reported by GitHub Actions (job `name`). Each must report on every pull request (no `paths` filters on its workflow): a missing check blocks the merge. They are not enforced on branch creation.

`bypass_apps` lists GitHub App IDs that always bypass the ruleset, e.g. a release App pushing a changelog commit to the default branch. Pushes authenticated by `GITHUB_TOKEN` cannot bypass: a repository releasing with `GITHUB_TOKEN` must opt out.

Rulesets need the App's repository Administration permission, see [GitHub App](#github-app).

### Removal Safety

Removing a repository from the YAML archives it instead of deleting it (`archive_on_destroy = true`).

### Branch Cleanup

Every repository is managed with `delete_branch_on_merge = true`, so GitHub deletes a pull request's head branch once it is merged. A deleted branch can be restored from its pull request.

### Merge Methods

Every repository allows rebase and squash merges only, merge commits are off. A squash merge commit takes its title and message from the commits, not the pull request: a single-commit pull request squashes into its commit subject, so it passes the [Rulesets](#rulesets) commit message pattern. A multi-commit pull request squash defaults to the pull request title; edit it or rebase instead.

### Issues

Every repository has issues enabled: GitHub Issues are the public intake.

### Secret Scanning

Public repositories are managed with secret scanning and push protection enabled, so GitHub alerts on committed secrets and blocks pushes containing them. Private repositories are left unmanaged (unavailable on the GitHub Free plan). Non-provider patterns and validity checks are not managed.

### Local Usage

Export the local equivalents from the [Use Terraform Action](#use-terraform-action) table, the PEM contents as `GITHUB_APP_PEM_FILE`, plus `TF_WORKSPACE` and `TF_VAR_config`, or when using direnv copy the templates [`.env.tmpl`](.env.tmpl), [`.env.plan.tmpl`](.env.plan.tmpl) and [`.env.apply.tmpl`](.env.apply.tmpl) without `.tmpl` and fill them in: `.env` holds the backend bucket and endpoint, owner and configuration path, `.env.plan` and `.env.apply` the credentials of the `plan` and apply environments; [`.envrc`](.envrc) sets `TF_WORKSPACE` to `GITHUB_OWNER`. `TF_VAR_config` is relative to `terraform/`, e.g. `../test.yaml`. Plan mode with read-only credentials is the default, apply credentials load only for a single command with `TF_MODE=apply`.

```shell
direnv allow
# direnv: loading ~/bruzit/github-organization-as-code/.envrc
# direnv: export +AWS_ACCESS_KEY_ID +AWS_BUCKET +AWS_ENDPOINT_URL_S3 +AWS_SECRET_ACCESS_KEY +GITHUB_APP_ID +GITHUB_APP_INSTALLATION_ID +GITHUB_APP_PEM_FILE +GITHUB_APP_PEM_FILE_PATH +GITHUB_OWNER +TF_VAR_config +TF_WORKSPACE

# Use Terraform as you need
terraform -chdir=terraform init -backend-config="bucket=$AWS_BUCKET"
terraform -chdir=terraform plan -lock=false -refresh=false
TF_MODE=apply direnv exec . terraform -chdir=terraform apply
```

## Support

Community, best effort; [open a GitHub issue](../../issues).

## Development

Format Terraform configuration by `terraform -chdir=terraform fmt -recursive`.

## Testing

Test by `terraform -chdir=terraform init -backend=false && terraform -chdir=terraform test`, the repository module by `terraform -chdir=terraform/modules/repository init -backend=false && terraform -chdir=terraform/modules/repository test`, the environment module likewise in `terraform/modules/environment`.

## Integration and Deployment

| Workflow                                                            | Trigger                          | Purpose                                                                                                                     |
|---------------------------------------------------------------------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| [MegaLinter](.github/workflows/megalinter.yaml)                     | Pull request                     | Lint changed files; required check `Required (MegaLinter)`                                                                  |
| [MegaLinter Scheduled](.github/workflows/megalinter-scheduled.yaml) | Weekly, Monday 06:00 UTC; manual | Lint the whole codebase                                                                                                     |
| [Terraform Test](.github/workflows/terraform-test.yaml)             | Pull request; push to `main`     | Formatting check and tests, Terraform 1.15 and 1.16; required check `Required (Terraform Test)`                             |
| [Terraform Plan](.github/workflows/terraform-plan.yaml)             | Pull request                     | Plan [`test.yaml`](test.yaml) against the test organization, `plan` environment; required check `Required (Terraform Plan)` |
| [Test](.github/workflows/test.yaml)                                 | Push to `main`                   | Apply `test.yaml` to the test organization, `test` environment                                                              |
| [Semantic Release](.github/workflows/semantic-release.yaml)         | Push to `main`                   | Version, changelog and GitHub release via the shared semantic-release action                                                |

## Contributing

Open a pull request to `main`. Commits follow the [Conventional Commits 1.0.0 specification](https://www.conventionalcommits.org/en/v1.0.0/), from which semantic-release sets versions and the changelog automatically.

## License and Copyright

MIT License: [`LICENSE`](LICENSE)  
Copyright © 2026 Martin Bružina

## References

- [BruzIT GitHub Actions and Workflows](https://github.com/bruzit/github-actions-and-workflows)
- [integrations/github Terraform provider documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)

## Stats

| Metric           | Badges                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Commits          | [![Commits total](https://img.shields.io/github/commit-activity/t/bruzit/github-organization-as-code?label=commits%20total)](https://github.com/bruzit/github-organization-as-code/commits/main)                                                                                                                                                                                                                                                                                                                   |
| Issues           | [![Issues open](https://img.shields.io/github/issues/bruzit/github-organization-as-code?label=issues)](https://github.com/bruzit/github-organization-as-code/issues) [![Issues total](https://img.shields.io/github/issues-search?query=repo%3Abruzit%2Fgithub-organization-as-code%20is%3Aissue&label=issues%20total)](https://github.com/bruzit/github-organization-as-code/issues?q=is%3Aissue)                                                                                                                 |
| Pull requests    | [![Pull requests open, not draft](https://img.shields.io/github/issues-search?query=repo%3Abruzit%2Fgithub-organization-as-code%20is%3Apr%20is%3Aopen%20draft%3Afalse&label=PRs%20open)](https://github.com/bruzit/github-organization-as-code/pulls?q=is%3Apr+is%3Aopen+draft%3Afalse) [![Pull requests total](https://img.shields.io/github/issues-search?query=repo%3Abruzit%2Fgithub-organization-as-code%20is%3Apr&label=PRs%20total)](https://github.com/bruzit/github-organization-as-code/pulls?q=is%3Apr) |
| Checks on `main` | [![Checks on main](https://img.shields.io/github/check-runs/bruzit/github-organization-as-code/main?label=checks%20%28main%29)](https://github.com/bruzit/github-organization-as-code/actions?query=branch%3Amain)                                                                                                                                                                                                                                                                                                 |
| Releases         | [![Latest release](https://img.shields.io/github/v/release/bruzit/github-organization-as-code)](https://github.com/bruzit/github-organization-as-code/releases/latest) [![Commits since latest release](https://img.shields.io/github/commits-since/bruzit/github-organization-as-code/latest)](https://github.com/bruzit/github-organization-as-code/releases)                                                                                                                                                    |
| Community        | [![Stargazers](https://img.shields.io/github/stars/bruzit/github-organization-as-code)](https://github.com/bruzit/github-organization-as-code/stargazers) [![Forks](https://img.shields.io/github/forks/bruzit/github-organization-as-code)](https://github.com/bruzit/github-organization-as-code/forks) [![Contributors](https://img.shields.io/github/contributors/bruzit/github-organization-as-code)](https://github.com/bruzit/github-organization-as-code/graphs/contributors)                              |
