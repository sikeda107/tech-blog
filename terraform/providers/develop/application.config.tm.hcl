generate_hcl "_terramate_generated_providers.tf" {
  content {
    provider "google" {
      project = global.application.develop.project
      region  = global.application.develop.region
      zone    = global.application.develop.zone
      default_labels = {
        "environment" = global.application.develop.environment
      }
      add_terraform_attribution_label = true
    }
  }
}