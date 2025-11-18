# Shared required GCP APIs for dev/staging/prod environments
# Note: cloudresourcemanager and serviceusage must be manually enabled before
# running Terraform for the first time (bootstrap requirement)

output "required_apis" {
  description = "List of required GCP APIs for application environments"
  value = [
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "discoveryengine.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
  ]
}
