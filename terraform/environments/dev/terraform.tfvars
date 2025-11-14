# Dev Environment Configuration
project_id        = "your-dev-project-id"
billing_project   = "your-dev-project-id" # Usually same as project_id unless using shared billing
project_name      = "sagent"
region            = "europe-west2"
data_store_region = "us"
environment       = "dev"

labels = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "knowsee"
}
