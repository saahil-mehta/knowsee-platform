# GCS bucket IAM permissions for staging

# Example Bucket IAM Binding:
# module "bucket_iam" {
#   source = "../modules/iam/bindings/bucket"
#
#   bucket = module.storage_buckets.staging_data_bucket_name
#
#   bindings = {
#     "roles/storage.objectViewer" = [
#       "serviceAccount:${module.service_accounts.example_sa_email}",
#     ]
#     "roles/storage.objectAdmin" = [
#       "serviceAccount:${module.service_accounts.admin_sa_email}",
#     ]
#   }
# }
