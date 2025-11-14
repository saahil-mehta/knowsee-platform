variable "project_id" {
  description = "Staging GCP project ID"
  type        = string
}

variable "billing_project" {
  description = "Project to use for quota and billing. Required when user_project_override is enabled. Usually same as project_id."
  type        = string
}

variable "project_name" {
  description = "Project name used as a base for resource naming"
  type        = string
  default     = "sagent"
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "europe-west2"
}

variable "data_store_region" {
  description = "Region for Vertex AI Discovery Engine datastore"
  type        = string
  default     = "us"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "staging"
    managed_by  = "terraform"
    project     = "knowsee"
  }
}
