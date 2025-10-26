# This file is template for terraform backend configuration.
# Please use generate-backend.sh to generate the terraform file.
terraform {
  required_version = ">= 1.13.4"

  backend "gcs" {
    bucket = "${GCS_BUCKET}"
    prefix = "${TERRAFORM_PREFIX}"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.8.0"
    }
  }
}

provider "google" {
  project = "${GCP_PROJECT}"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"

  default_labels = {
    # environment = "${ENVIRONMENT}"
  }
}

provider "google-beta" {
  project = "${GCP_PROJECT}"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"

  default_labels = {
    # environment = "${ENVIRONMENT}"
  }
}
