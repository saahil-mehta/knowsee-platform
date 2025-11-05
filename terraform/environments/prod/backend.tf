# Terraform backend configuration for prod environment
# Configure GCS backend for remote state storage

terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-prod"  # Update with your GCS bucket name
    prefix = "terraform/prod"
  }
}
