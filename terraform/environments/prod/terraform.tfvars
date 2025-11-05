# Variable values for prod environment
# Update these with your actual GCP project details

project_id  = "your-prod-project-id"
region      = "us-central1"
environment = "prod"

# Enable required GCP APIs
enable_apis = [
  "compute.googleapis.com",
  "storage.googleapis.com",
  "bigquery.googleapis.com",
  "cloudfunctions.googleapis.com",
  "cloudscheduler.googleapis.com",
  "secretmanager.googleapis.com",
  "iam.googleapis.com",
]

# Common labels for all resources
labels = {
  environment = "prod"
  managed_by  = "terraform"
  project     = "knowsee"
}

# Storage buckets configuration
storage_buckets = {
  # "prod-data-bucket" = {
  #   location      = "us-central1"
  #   storage_class = "STANDARD"
  #   versioning    = true
  # }
}

# BigQuery datasets configuration
bigquery_datasets = {
  # "prod_analytics" = {
  #   location                    = "US"
  #   delete_contents_on_destroy  = false  # Keep data in prod
  #   default_table_expiration_ms = 0       # No expiration in prod
  # }
}

# Service accounts configuration
service_accounts = {
  # "prod-app-sa" = {
  #   display_name = "Production Application Service Account"
  #   description  = "Service account for production application workloads"
  # }
}
