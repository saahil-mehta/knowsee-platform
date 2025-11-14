output "cloud_run_services" {
  description = "Cloud Run services for dev environment"
  value = {
    backend = {
      name                             = "${var.project_name}-backend"
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
          value = "${var.project_name}-datastore"
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
    # Uncomment when frontend is ready
    # frontend = {
    #   name                             = "${var.project_name}-frontend"
    #   location                         = var.region
    #   image                            = "us-docker.pkg.dev/cloudrun/container/hello"
    #   cpu                              = "2"
    #   memory                           = "4Gi"
    #   cpu_idle                         = true
    #   min_instance_count               = 0
    #   max_instance_count               = 10
    #   max_instance_request_concurrency = 80
    #   session_affinity                 = false
    #   service_account_key              = "app"
    #   env_vars = [
    #     {
    #       name  = "NEXT_PUBLIC_AGUI_URL"
    #       value = "https://${var.project_name}-backend-xxxxx-ew.a.run.app/api/agui"
    #     }
    #   ]
    #   secret_env_vars = []
    #   labels = {
    #     created-by = "adk"
    #   }
    # }
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "data_store_region" {
  description = "Vertex AI Discovery Engine datastore region"
  type        = string
}
