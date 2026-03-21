terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket               = "bruzit-terraform-github"
    workspace_key_prefix = ""
    key                  = "terraform.tfstate"
    use_lockfile         = true # Set to false only for non-AWS S3 compatible APIs without "conditional object PUTs" capability
    region               = "us-east-1"

    # Only for non-AWS S3 compatible APIs
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }
}

provider "github" {
  app_auth {}
}
