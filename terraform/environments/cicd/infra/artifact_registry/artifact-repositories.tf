output "artifact_repositories" {
  description = "Artifact Registry repositories for Docker images"
  value = {
    genai_repo = {
      repository_id = "${var.project_name}-repo"
      location      = var.region
      description   = "Docker repository for generative AI applications"
      format        = "DOCKER"
      project_id    = var.project_id
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
