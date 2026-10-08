# GitHub Organization as Code

GitOps workflow turning a declarative YAML organization definition into GitHub resources with Terraform, authenticated by a GitHub App.

## Features

- **Automated GitHub Organization management** - Define repositories using simple YAML file.
  - **Repository metadata** - Define description, homepage URL, topics.
  - **Environments** - Define deployment environments per repository or once for every repository.
    - **Variables and secrets** - Define environment variables and secret placeholders.
  - **Rulesets** - Protect default branches and release tags per repository or once for every repository.
- **GitOps Composite Action** - Manage configurations using pull requests and automate updates using a [composite action](action.yaml).
- **Terraform** - Uses Terraform under the hood to apply changes efficiently.
- **Terraform State Management** - Stores Terraform state in an S3-compatible bucket, e.g. Cloudflare R2, one workspace per organization.
- **GitHub App Integration** - Uses a GitHub App for authentication and API interactions.

## Installation and Configuration

- Configure an S3-compatible bucket to store Terraform state files, see [Terraform State Backend](#terraform-state-backend).
- Set up a GitHub App and its installation to handle authentication and authorization for your GitHub Organization.
- Implement GitOps by setting up a GitHub repository with:
  - YAML-based configuration
  - GitHub workflows
  - Environment variables and secrets

### Terraform State Backend

The [S3 backend](terraform/config.tf) works with any S3-compatible storage; BruzIT uses Cloudflare R2 with the bucket `bruzit-terraform-github`. The action passes the bucket at init (`-backend-config="bucket=..."` from `aws-bucket`) and the endpoint as `AWS_ENDPOINT_URL_S3` (from `aws-endpoint-url-s3`, e.g. `https://ACCOUNT_ID.r2.cloudflarestorage.com`). `skip_credentials_validation` and `skip_requesting_account_id` skip the AWS STS and IAM calls non-AWS storage does not serve; `use_lockfile` locks the state with a lock object in the bucket, which needs conditional writes.

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

### Configuration File

Create GitHub organization YAML configuration file. See [GitHub Organization Configuration YAML](#github-organization-configuration-yaml) below.

For example, `config.yaml`:

```yaml
---
repositories:
  - name: .github
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

The [action](action.yaml) runs the Terraform code shipped with the action against the configuration file at `path`, relative to the workspace, so the caller checks out its repository first. It sets up the latest Terraform, checks formatting, initializes the S3 backend in `aws-bucket`, selects the workspace named after `owner`, validates, and applies with `-auto-approve`. `concurrency` queues pushes instead of failing the apply on the state lock.

`mode: plan` runs `terraform plan -lock=false -refresh=false` instead of the apply, for pull requests with read-only credentials (a read-only S3 key cannot write the state lock); no refresh, it compares against the last applied state. Run it on `pull_request` with `environment: plan`.

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
```

### Members

`organization.members.admins` lists the organization owners. Only owners are managed: other members, teams and outside collaborators stay unmanaged. A listed user who is not a member yet is invited and stays pending until they accept. Every owner has `prevent_destroy`, so removing one from the list fails the plan; demote or remove an owner explicitly (`removed` block or `terraform state rm`). Existing memberships are imported, which needs the Terraform workspace named after the organization.

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

A `branch` ruleset (default `target`) protects the repository's default branch: changes only through a pull request (no approval required, so a single maintainer can merge their own), no force pushes, no deletion, linear history, [conventional commit](https://www.conventionalcommits.org/) messages with a lowercase subject. No required status checks.

A `tag` ruleset protects release tags `vX.Y.Z` (`refs/tags/v*.*.*`): no update, no deletion; creation stays allowed, e.g. for semantic-release. Major tags `vN` do not match, so a release App can still move them.

On the GitHub Free plan, rulesets are available in public repositories only.

`bypass_apps` lists GitHub App IDs that always bypass the ruleset, e.g. a release App pushing a changelog commit to the default branch. Pushes authenticated by `GITHUB_TOKEN` cannot bypass: a repository releasing with `GITHUB_TOKEN` must opt out.

Rulesets need the App's repository Administration permission, see [GitHub App](#github-app).

### Removal Safety

Removing a repository from the YAML archives it instead of deleting it. Every repository is created with `archive_on_destroy = true`, so `terraform apply` after a removal archives the repository — the live repository is preserved while being removed from the organization's active configuration.

### Branch Cleanup

Every repository is managed with `delete_branch_on_merge = true`, so GitHub deletes a pull request's head branch once it is merged. A deleted branch can be restored from its pull request.

### Merge Methods

Every repository allows rebase and squash merges only, merge commits are off. A squash merge commit takes its title and message from the commits, not the pull request: a single-commit pull request squashes into its commit subject, so it passes the [ruleset](#rulesets) commit message pattern. A multi-commit pull request squash defaults to the pull request title; edit it or rebase instead.

### Issues

Every repository has issues enabled: GitHub Issues are the public intake.

### Secret Scanning

Every repository is managed with secret scanning and push protection enabled, so GitHub alerts on committed secrets and blocks pushes containing them. Non-provider patterns and validity checks are not managed.

Set it as source of truth:

```shell
# The path is relative to the terraform main module (terraform directory)
export TF_VAR_config="../test.yaml"
```

### Local Usage

Export the local equivalents from the [table above](#use-terraform-action), the PEM contents as `GITHUB_APP_PEM_FILE`, plus `TF_WORKSPACE` and `TF_VAR_config`, or when using direnv copy the templates [`.env.tmpl`](.env.tmpl), [`.env.plan.tmpl`](.env.plan.tmpl) and [`.env.apply.tmpl`](.env.apply.tmpl) without `.tmpl` and fill them in: `.env` holds the backend bucket and endpoint, owner and configuration path, `.env.plan` and `.env.apply` the credentials of the `plan` and apply environments; [`.envrc`](.envrc) sets `TF_WORKSPACE` to `GITHUB_OWNER`. Plan mode with read-only credentials is the default, apply credentials load only for a single command with `TF_MODE=apply`.

```shell
direnv allow
# direnv: loading ~/bruzit/github-organization-as-code/.envrc
# direnv: export +AWS_ACCESS_KEY_ID +AWS_BUCKET +AWS_ENDPOINT_URL_S3 +AWS_SECRET_ACCESS_KEY +GITHUB_APP_ID +GITHUB_APP_INSTALLATION_ID +GITHUB_APP_PEM_FILE +GITHUB_APP_PEM_FILE_PATH +GITHUB_OWNER +TF_VAR_config +TF_WORKSPACE

# Use Terraform as you need
terraform -chdir=terraform init -backend-config="bucket=$AWS_BUCKET"
terraform -chdir=terraform plan -lock=false -refresh=false
TF_MODE=apply direnv exec . terraform -chdir=terraform apply
```

## Development

Format Terraform configuration by `terraform -chdir=terraform fmt -recursive`.

Test by `terraform -chdir=terraform init -backend=false && terraform -chdir=terraform test`, the repository module by `terraform -chdir=terraform/modules/repository init -backend=false && terraform -chdir=terraform/modules/repository test`, the environment module likewise in `terraform/modules/environment`.

## Copyright and Licensing

[MIT License](LICENSE)  
Copyright © 2026 Martin Bružina
