# Staging Environment Configuration
project_id        = "your-staging-project-id"
billing_project   = "your-staging-project-id" # Usually same as project_id unless using shared billing
project_name      = "sagent"
region            = "europe-west2"
data_store_region = "us"
environment       = "staging"

labels = {
  environment = "staging"
  managed_by  = "terraform"
  project     = "knowsee"
}
