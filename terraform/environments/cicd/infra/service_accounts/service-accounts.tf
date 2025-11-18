output "service_accounts" {
  description = "Service accounts for CICD project"
  value = {
    cicd_runner = {
      account_id   = "${var.project_name}-cb"
      display_name = "CICD Runner Service Account"
      description  = "Service account for CI/CD pipelines (GitHub Actions, Cloud Build)"
      project_id   = var.project_id
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
