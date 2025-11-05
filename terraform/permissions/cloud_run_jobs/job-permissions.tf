# Cloud Run job IAM permissions for staging

# Example Cloud Run Job IAM Binding:
# module "cloud_run_job_iam" {
#   source = "../modules/iam/bindings/cloud_run_jobs"
#
#   project_id = var.project_id
#   location   = var.region
#   job_name   = "staging-example-job"
#
#   bindings = {
#     "roles/run.invoker" = [
#       "serviceAccount:${module.service_accounts.invoker_sa_email}",
#     ]
#   }
# }
