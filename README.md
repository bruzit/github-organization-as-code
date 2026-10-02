# GitHub Organization as Code

GitOps workflow turning a declarative YAML organization definition into GitHub resources with Terraform, authenticated by a GitHub App.

## Features

- **Automated GitHub Organization management** - Define repositories using simple YAML file.
  - **Repository metadata** - Define description, homepage URL, topics.
- **GitOps Composite Action** - Manage configurations using pull requests and automate updates using a [composite action](action.yaml).
- **Terraform** - Uses Terraform under the hood to apply changes efficiently.
- **Terraform State Management** - Stores Terraform state securely in AWS S3.
- **GitHub App Integration** - Uses a GitHub App for authentication and API interactions.

## Installation and Configuration

- Configure an AWS S3 bucket to store Terraform state files.
- Set up a GitHub App and its installation to handle authentication and authorization for your GitHub Organization.
- Implement GitOps by setting up a GitHub repository with:
  - YAML-based configuration
  - GitHub workflows
  - Repository variables and secrets

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
      - Organization permissions
        - Administration: Read and write
      - Where can this GitHub App be installed?: _choose what suits you best_
    - **Create GitHub App**
  - _your app_
    - General
      - **Generate a private key**
    - Install App
      - _your organization_: **Install**

### GitHub Organization as Code

Create GitHub organization YAML configuration file. See [GitHub Organization YAML](#github-organization-yaml) below.

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
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          persist-credentials: false
      - name: Terraform
        uses: bruzit/github-organization-as-code@v0
        with:
          aws-bucket: ${{ vars.AWS_TF_BUCKET }}
          aws-endpoint-url-s3: ${{ vars.AWS_ENDPOINT_URL_S3 }}
          owner: ${{ vars.GH_TF_OWNER }}
          app-id: ${{ vars.GH_TF_APP_ID }}
          app-installation-id: ${{ vars.GH_TF_APP_INSTALLATION_ID }}
          path: config.yaml
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          app-private-key: ${{ secrets.GH_TF_APP_PEM_FILE }}
```

The [action](action.yaml) runs the Terraform code shipped with the action against the configuration file at `path`, relative to the workspace, so the caller checks out its repository first. It sets up the latest Terraform, checks formatting, initializes the S3 backend in `aws-bucket`, selects the workspace named after `owner`, validates, and applies with `-auto-approve`. `concurrency` queues pushes instead of failing the apply on the state lock.

Set up GitHub actions, variables and secrets:

- GitHub / _Repository_ / Settings
  - Secrets and variables / Actions / Actions secrets and variables
    - Secrets
      - **New repository secret**
        - `GH_TF_APP_PEM_FILE` (`GITHUB_APP_PEM_FILE_PATH` contents)
        - `AWS_ACCESS_KEY_ID`
        - `AWS_SECRET_ACCESS_KEY`
    - Variables
      - **New repository variable**
        - `GH_TF_OWNER` (`GITHUB_OWNER`)
        - `GH_TF_APP_ID` (`GITHUB_APP_ID`)
        - `GH_TF_APP_INSTALLATION_ID` (`GITHUB_APP_INSTALLATION_ID`)
        - `AWS_ENDPOINT_URL_S3`
        - `AWS_TF_BUCKET` (S3 bucket name for Terraform state)

### Use Terraform Workflow

Similar to [Use Terraform Action](#use-terraform-action), with the reusable workflow:

```yaml
---
name: GitHub Organization as Code

on:
  push:
    branches:
      - main

jobs:
  call-terraform:
    uses: bruzit/github-organization-as-code/.github/workflows/terraform.yaml@v0
    with:
      aws_bucket: ${{ vars.AWS_TF_BUCKET }}
      aws_endpoint_url_s3: ${{ vars.AWS_ENDPOINT_URL_S3 }}
      gh_tf_owner: ${{ vars.GH_TF_OWNER }}
      gh_tf_app_id: ${{ vars.GH_TF_APP_ID }}
      gh_tf_app_installation_id: ${{ vars.GH_TF_APP_INSTALLATION_ID }}
      path: config.yaml
    secrets:
      aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      gh_tf_app_pem_file: ${{ secrets.GH_TF_APP_PEM_FILE }}
```

## Usage

### GitHub Organization Configuration YAML

Create the configuration file:

```yaml
---
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
```

### Removal Safety

Removing a repository from the YAML archives it instead of deleting it. Every repository is created with `archive_on_destroy = true`, so `terraform apply` after a removal archives the repository — the live repository is preserved while being removed from the organization's active configuration.

### Branch Cleanup

Every repository is managed with `delete_branch_on_merge = true`, so GitHub deletes a pull request's head branch once it is merged. A deleted branch can be restored from its pull request.

Set it as source of truth:

```shell
# The path is relative to the terraform main module (terraform directory)
export TF_VAR_config="../test.yaml"
```

### Local Usage

Export variables `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and `GITHUB_APP_PEM_FILE`, or when using direnv copy the template [`.env.tmpl`](.env.tmpl) to `.env` and fill it in.

```shell
direnv allow
# direnv: loading ~/bruzit/github-organization-as-code/.envrc
# direnv: export +AWS_ACCESS_KEY_ID +AWS_BUCKET +AWS_ENDPOINT_URL_S3 +AWS_SECRET_ACCESS_KEY +GITHUB_APP_ID +GITHUB_APP_INSTALLATION_ID +GITHUB_APP_PEM_FILE +GITHUB_APP_PEM_FILE_PATH +GITHUB_OWNER +TF_VAR_config

# Use Terraform as you need
terraform -chdir=terraform init -backend-config="bucket=$AWS_BUCKET"
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

## Development

Format Terraform configuration by `terraform -chdir=terraform fmt -recursive`.

Test by `terraform -chdir=terraform init -backend=false && terraform -chdir=terraform test`.

## Copyright and Licensing

[MIT License](LICENSE)  
Copyright © 2026 Martin Bružina
