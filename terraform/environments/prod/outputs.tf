# Outputs for prod environment

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "service_account_emails" {
  description = "Map of service account names to their email addresses"
  value = {
    for k, v in module.service_accounts : k => v.email
  }
}

output "storage_bucket_names" {
  description = "Map of storage bucket identifiers to their names"
  value = {
    for k, v in module.storage_buckets : k => v.name
  }
}

output "bigquery_dataset_ids" {
  description = "Map of BigQuery dataset identifiers to their IDs"
  value = {
    for k, v in module.bigquery_datasets : k => v.dataset_id
  }
}
