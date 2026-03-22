# GitHub Organization as Code

GitHub organization managed as code.

## Features

- **Automated GitHub Organization management** - Define repositories using simple YAML file.
- **Reusable GitOps Workflow** - Manage configurations using pull requests and automate updates using GitHub Actions.
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

### GitHub Workflow

Create the workflow:

```yaml
---
on:
  push:
    branches:
      - main

jobs:
  call-terraform:
    uses: bruzit/github-organization-as-code/.github/workflows/terraform.yaml@v0
    with:
      aws_endpoint_url_s3: ${{ vars.AWS_ENDPOINT_URL_S3 }}
      gh_owner: ${{ vars.GH_TF_OWNER }}
      gh_app_id: ${{ vars.GH_TF_APP_ID }}
      gh_app_installation_id: ${{ vars.GH_TF_APP_INSTALLATION_ID }}
      path: config.yaml
    secrets:
      aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      gh_app_pem_file: ${{ secrets.GH_TF_APP_PEM_FILE }}
```

Set up GitHub actions, variables and secrets:

- GitHub / *Repository* / Settings
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

## Usage

### GitHub Organization Configuration YAML

Create the configuration file:

```yaml
---
repositories:
  - name: repo-slug
```

Set it as source of truth:

```shell
# The path is relative to the terraform main module (terraform directory)
export TF_VAR_config="../test.yaml"
```

### Local Usage

Export variables `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and `GITHUB_APP_PEM_FILE`, or when using direnv set up [`.env`](.env) as shown in the template [`.env.tmpl`](.env.tmpl).

```shell
direnv allow
# direnv: loading ~/bruzit/github-organization-as-code/.envrc
# direnv: export +AWS_ACCESS_KEY_ID +AWS_ENDPOINT_URL_S3 +AWS_SECRET_ACCESS_KEY +GITHUB_APP_ID +GITHUB_APP_INSTALLATION_ID +GITHUB_APP_PEM_FILE +GITHUB_APP_PEM_FILE_PATH +GITHUB_OWNER +TF_VAR_config

# Use Terraform as you need
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

## Development

Format Terraform configuration by `terraform -chdir=terraform fmt -recursive`.

## Copyright and Licensing

[MIT License](LICENSE)  
Copyright © 2026 Martin Bružina
