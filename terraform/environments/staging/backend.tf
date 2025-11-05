# Terraform backend configuration for staging environment
# Configure GCS backend for remote state storage

terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-staging"  # Update with your GCS bucket name
    prefix = "terraform/staging"
  }
}
