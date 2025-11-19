/*
  Cloud Run IAM bindings for service-to-service communication
  Grants the app service account permission to invoke Cloud Run services.
*/

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Cloud Run region"
  type        = string
}

locals {
  service_account_email = "${var.resource_prefix}-${var.environment}-app@${var.project_id}.iam.gserviceaccount.com"
  backend_service_name  = "${var.resource_prefix}-${var.environment}-backend"
}

# Grant the app service account permission to invoke the backend service
# This enables frontend-to-backend authenticated communication
resource "google_cloud_run_v2_service_iam_member" "backend_invoker" {
  project  = var.project_id
  location = var.region
  name     = local.backend_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.service_account_email}"
}
