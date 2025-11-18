# Shared service accounts configuration for dev/staging/prod environments

locals {
  service_accounts = {
    app = {
      account_id   = "${var.resource_prefix}-${var.environment}-app"
      display_name = "${var.resource_prefix} ${var.environment} Agent Service Account"
      description  = "Service account for running the ADK agent application"
      project_id   = var.project_id
      roles = [
        "roles/aiplatform.user",
        "roles/discoveryengine.editor",
        "roles/logging.logWriter",
        "roles/cloudtrace.agent",
        "roles/storage.admin",
        "roles/serviceusage.serviceUsageConsumer",
      ]
    }
    vertexai_pipeline = {
      account_id   = "${var.resource_prefix}-${var.environment}-rag"
      display_name = "${var.resource_prefix} ${var.environment} Vertex AI Pipeline Service Account"
      description  = "Service account for Vertex AI data ingestion pipeline"
      project_id   = var.project_id
      roles = [
        "roles/storage.admin",
        "roles/aiplatform.user",
        "roles/discoveryengine.admin",
        "roles/logging.logWriter",
        "roles/artifactregistry.writer",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/bigquery.readSessionUser",
        "roles/bigquery.connectionAdmin",
        "roles/resourcemanager.projectIamAdmin"
      ]
    }
  }
}
