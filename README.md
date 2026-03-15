# GitHub Organization as Code

GitHub organization managed as code.

## Setup

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

## Usage

Export variables `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and `GITHUB_APP_PEM_FILE`, or when using direnv set up [`.env`](.env) as shown in the template [`.env.tmpl`](.env.tmpl).

```shell
direnv allow
# direnv: loading ~/bruzit/github-organization-as-code/.envrc
# direnv: export +GH_OWNER +GITHUB_APP_ID +GITHUB_APP_INSTALLATION_ID +GITHUB_APP_PEM_FILE

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
