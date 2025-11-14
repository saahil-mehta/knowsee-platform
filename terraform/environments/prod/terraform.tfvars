# Production Environment Configuration
project_id        = "your-prod-project-id"
billing_project   = "your-prod-project-id" # Usually same as project_id unless using shared billing
project_name      = "sagent"
region            = "europe-west2"
data_store_region = "us"
environment       = "prod"

labels = {
  environment = "prod"
  managed_by  = "terraform"
  project     = "knowsee"
}
