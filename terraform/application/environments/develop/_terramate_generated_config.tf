// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_version = "~> 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.12.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.12.0"
    }
  }
  backend "gcs" {
    bucket = "terraform-remote-backend"
    prefix = "state/application-develop"
  }
}
