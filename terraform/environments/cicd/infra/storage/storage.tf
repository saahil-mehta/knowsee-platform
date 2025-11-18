output "storage_buckets" {
  description = "GCS buckets for CICD project"
  value = {
    logs = {
      name          = "${var.project_id}-${var.project_name}-logs"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
      labels        = var.labels
    }
  }
}

variable "project_id" {
  description = "CICD project ID"
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

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
}
