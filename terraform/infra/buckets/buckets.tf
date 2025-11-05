# Storage buckets configuration for staging
# Add bucket definitions here or manage via main.tf storage_buckets variable

# Example:
# module "custom_bucket" {
#   source = "../modules/cloud_storage/buckets"
#
#   project_id    = var.project_id
#   name          = "staging-custom-bucket"
#   location      = var.region
#   storage_class = "STANDARD"
#
#   versioning = {
#     enabled = true
#   }
#
#   lifecycle_rules = [{
#     action = {
#       type = "Delete"
#     }
#     condition = {
#       age = 30
#     }
#   }]
# }
