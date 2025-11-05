# Variable values for staging environment
# Update these with your actual GCP project details

project_id  = "your-staging-project-id"
region      = "us-central1"
environment = "staging"

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
  environment = "staging"
  managed_by  = "terraform"
  project     = "knowsee"
}

# Storage buckets configuration
storage_buckets = {
  # "staging-data-bucket" = {
  #   location      = "us-central1"
  #   storage_class = "STANDARD"
  #   versioning    = true
  # }
}

# BigQuery datasets configuration
bigquery_datasets = {
  # "staging_analytics" = {
  #   location                    = "US"
  #   delete_contents_on_destroy  = true
  #   default_table_expiration_ms = 2592000000  # 30 days
  # }
}

# Service accounts configuration
service_accounts = {
  # "staging-app-sa" = {
  #   display_name = "Staging Application Service Account"
  #   description  = "Service account for staging application workloads"
  # }
}
