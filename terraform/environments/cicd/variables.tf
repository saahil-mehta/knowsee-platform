variable "project_id" {
  description = "CICD runner GCP project ID"
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

variable "repository_owner" {
  description = "GitHub repository owner (username or organisation)"
  type        = string
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "cicd"
    managed_by  = "terraform"
    project     = "knowsee"
  }
}
