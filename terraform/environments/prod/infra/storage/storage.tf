output "storage_buckets" {
  description = "GCS buckets for dev project"
  value = {
    logs = {
      name          = "${var.project_id}-${var.project_name}-logs"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
    }
    rag_pipeline = {
      name          = "${var.project_id}-${var.project_name}-rag"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
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

variable "region" {
  description = "GCP region"
  type        = string
}
