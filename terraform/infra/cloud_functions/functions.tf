# Cloud Functions configuration for staging

# Example Gen2 Cloud Function:
# module "example_function" {
#   source = "../modules/cloud_functions/gen2"
#
#   project_id   = var.project_id
#   name         = "staging-example-function"
#   location     = var.region
#   description  = "Example cloud function"
#   runtime      = "python311"
#   entry_point  = "main"
#
#   source_archive_bucket = module.buckets.function_source_bucket_name
#   source_archive_object = "path/to/function.zip"
#
#   environment_variables = {
#     ENV = "staging"
#   }
# }
