# Shared Artifact Registry configuration for dev/staging/prod environments

locals {
  artifact_registries = {
    app = {
      repository_id  = "${var.resource_prefix}-${var.environment}-app"
      location       = var.region
      format         = "DOCKER"
      description    = "Docker images for ${var.environment} application services"
      immutable_tags = false
    }
  }
}
