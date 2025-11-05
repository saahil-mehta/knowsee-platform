# Cloud Run jobs configuration for staging

# Example Cloud Run Job:
# module "example_job" {
#   source = "../modules/cloud_run_job"
#
#   project_id = var.project_id
#   name       = "staging-example-job"
#   location   = var.region
#
#   image = "gcr.io/${var.project_id}/example-image:latest"
#
#   env_vars = [
#     {
#       name  = "ENV"
#       value = "staging"
#     }
#   ]
#
#   service_account_email = module.service_accounts.example_sa_email
# }
