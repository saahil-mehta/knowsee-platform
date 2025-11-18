# Shared storage buckets configuration for dev/staging/prod environments

locals {
  storage_buckets = {
    logs = {
      name          = "${var.project_id}-logs"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
    }
    rag_pipeline = {
      name          = "${var.project_id}-rag"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
    }
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}
