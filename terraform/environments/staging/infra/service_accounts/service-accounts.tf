output "service_accounts" {
  description = "Service accounts for dev project"
  value = {
    app = {
      account_id   = "${var.project_name}-app"
      display_name = "${var.project_name} Agent Service Account"
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
      account_id   = "${var.project_name}-rag"
      display_name = "Vertex AI Pipeline Service Account"
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

variable "project_id" {
  description = "Dev project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}
