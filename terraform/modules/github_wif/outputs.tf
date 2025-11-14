output "pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.pool.workload_identity_pool_id
}

output "pool_name" {
  description = "Full resource name of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.pool.name
}

output "provider_id" {
  description = "ID of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.provider.workload_identity_pool_provider_id
}

output "provider_name" {
  description = "Full resource name of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.provider.name
}

output "workload_identity_pool_provider_name" {
  description = "Full provider name for use in workflows"
  value       = "projects/${var.project_id}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.provider.workload_identity_pool_provider_id}"
}
