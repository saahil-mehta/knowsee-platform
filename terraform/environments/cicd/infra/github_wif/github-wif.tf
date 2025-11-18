output "github_wif_config" {
  description = "GitHub Workload Identity Federation configuration"
  value = {
    pool_id               = "${var.project_name}-pool"
    pool_display_name     = "GitHub Actions Pool"
    provider_id           = "${var.project_name}-oidc"
    provider_display_name = "GitHub OIDC Provider"
    repository_owner      = var.repository_owner
    repository_name       = var.repository_name
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "repository_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
}
