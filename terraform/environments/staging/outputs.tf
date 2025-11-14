output "project_id" {
  description = "Staging project ID"
  value       = var.project_id
}

output "project_number" {
  description = "Staging project number"
  value       = data.google_project.project.number
}

output "app_service_account_email" {
  description = "Email of the app service account"
  value       = module.service_accounts["app"].email
}

output "vertexai_pipeline_service_account_email" {
  description = "Email of the Vertex AI pipeline service account"
  value       = module.service_accounts["vertexai_pipeline"].email
}

output "data_store_id" {
  description = "Vertex AI Discovery Engine data store ID"
  value       = module.discovery_engine.data_store_id
}

output "search_engine_id" {
  description = "Vertex AI Discovery Engine search engine ID"
  value       = module.discovery_engine.search_engine_id
}

output "cloud_run_services" {
  description = "Cloud Run services"
  value = {
    for key, service in module.cloud_run_services :
    key => {
      name     = service.service_name
      url      = service.service_url
      location = service.service_location
    }
  }
}

output "backend_url" {
  description = "URL of the backend Cloud Run service"
  value       = module.cloud_run_services["backend"].service_url
}

output "rag_pipeline_bucket" {
  description = "GCS bucket for RAG pipeline"
  value       = module.storage_buckets["rag_pipeline"].name
}

output "logs_bucket" {
  description = "GCS bucket for logs"
  value       = module.storage_buckets["logs"].name
}

output "telemetry_dataset" {
  description = "BigQuery dataset for telemetry logs"
  value       = module.log_sinks["telemetry"].dataset_id
}

output "feedback_dataset" {
  description = "BigQuery dataset for feedback logs"
  value       = module.log_sinks["feedback"].dataset_id
}
