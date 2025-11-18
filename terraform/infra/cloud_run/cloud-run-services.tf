# Shared Cloud Run services configuration for dev/staging/prod environments

locals {
  cloud_run_services = {
    backend = {
      name                             = "${var.resource_prefix}-${var.environment}-backend"
      location                         = var.region
      image                            = "us-docker.pkg.dev/cloudrun/container/hello"
      cpu                              = "4"
      memory                           = "8Gi"
      cpu_idle                         = false
      min_instance_count               = 1
      max_instance_count               = 10
      max_instance_request_concurrency = 40
      session_affinity                 = true
      service_account_key              = "app"
      env_vars = [
        {
          name  = "DATA_STORE_ID"
          value = "${var.resource_prefix}-${var.environment}-datastore"
        },
        {
          name  = "DATA_STORE_REGION"
          value = var.data_store_region
        }
      ]
      secret_env_vars = []
      labels = {
        created-by = "adk"
      }
    }
    frontend = {
      name                             = "${var.resource_prefix}-${var.environment}-frontend"
      location                         = var.region
      image                            = "us-docker.pkg.dev/cloudrun/container/hello"
      cpu                              = "1"
      memory                           = "512Mi"
      cpu_idle                         = true
      min_instance_count               = 0
      max_instance_count               = 10
      max_instance_request_concurrency = 80
      session_affinity                 = false
      service_account_key              = "app"
      env_vars = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "NEXT_PUBLIC_COPILOT_AGENT"
          value = "sagent_copilot"
        }
      ]
      secret_env_vars = []
      labels = {
        created-by = "copilotkit"
      }
    }
  }
}
