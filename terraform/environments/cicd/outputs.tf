output "project_id" {
  description = "CICD project ID"
  value       = var.project_id
}

output "project_number" {
  description = "CICD project number"
  value       = data.google_project.project.number
}

output "cicd_service_account_email" {
  description = "Email of the CICD runner service account"
  value       = module.service_accounts["cicd_runner"].email
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository for Docker images"
  value = {
    for key, repo in google_artifact_registry_repository.repositories :
    key => {
      id       = repo.id
      name     = repo.name
      location = repo.location
    }
  }
}

output "workload_identity_pool_id" {
  description = "Workload Identity Pool ID"
  value       = module.github_wif.pool_id
}

output "workload_identity_provider_id" {
  description = "Workload Identity Provider ID"
  value       = module.github_wif.provider_id
}

output "workload_identity_provider_name" {
  description = "Full Workload Identity Provider name for GitHub Actions"
  value       = module.github_wif.workload_identity_pool_provider_name
}

output "logs_bucket_name" {
  description = "Name of the logs bucket"
  value       = module.storage_buckets["logs"].name
}
