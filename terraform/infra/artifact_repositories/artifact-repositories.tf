# Artifact Registry repositories for staging

# Example Docker Repository:
# module "example_docker_repo" {
#   source = "../modules/artifact_registry_repository"
#
#   project_id    = var.project_id
#   repository_id = "staging-docker-repo"
#   location      = var.region
#   format        = "DOCKER"
#   description   = "Docker images for staging"
#
#   labels = local.common_labels
# }
