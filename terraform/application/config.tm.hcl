globals {

  terraform_version                 = "~> 1.9.0"
  terraform_google_provider_version = "~> 6.12.0"
  backend_bucket                    = "terraform-remote-backend"

  application = {
    production = {
      environment = "production"
      project     = "PROJECT_ID"
      region      = "asia-northeast1"
      zone        = "asia-northeast1-a"
    }
    develop = {
      environment = "develop"
      project     = "PROJECT_ID"
      region      = "asia-northeast1"
      zone        = "asia-northeast1-a"
    }
    staging = {
      environment = "staging"
      project     = "PROJECT_ID"
      region      = "asia-northeast1"
      zone        = "asia-northeast1-a"
    }
  }
}

generate_hcl "_terramate_generated_config.tf" {
  content {
    terraform {
      required_version = global.terraform_version
      required_providers {
        google = {
          source  = "hashicorp/google"
          version = global.terraform_google_provider_version
        }
        google-beta = {
          source  = "hashicorp/google-beta"
          version = global.terraform_google_provider_version
        }
      }
      backend "gcs" {
        bucket = global.backend_bucket
        prefix = "state/${terramate.stack.name}"
      }
    }
  }
}