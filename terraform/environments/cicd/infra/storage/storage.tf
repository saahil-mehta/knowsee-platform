# CICD storage buckets configuration

locals {
  buckets = {
    logs = {
      name          = "${var.resource_prefix}-${var.environment}-logs"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = false
      force_destroy = true
      labels        = var.labels
    }
  }
}

output "buckets" {
  description = "GCS buckets for CICD project"
  value       = local.buckets
}

variable "resource_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
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
