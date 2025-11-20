resource "google_cloud_run_v2_service" "service" {
  name                = var.name
  location            = var.location
  project             = var.project_id
  deletion_protection = var.deletion_protection
  ingress             = var.ingress
  labels              = var.labels

  template {
    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = var.cpu_idle
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name = env.value.name
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }
    }

    service_account                  = var.service_account_email
    max_instance_request_concurrency = var.max_instance_request_concurrency

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    session_affinity = var.session_affinity
  }

  traffic {
    type    = var.traffic_type
    percent = var.traffic_percent
  }

  # This lifecycle block prevents Terraform from overwriting container config when it's
  # updated by Cloud Run deployments outside of Terraform (e.g., via CI/CD pipelines)
  # Note: lifecycle blocks cannot use variables, so this always ignores these changes
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].containers[0].env,
      scaling,
      client,
      client_version,
    ]
  }
}
