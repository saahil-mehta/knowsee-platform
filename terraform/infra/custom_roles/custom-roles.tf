# Custom IAM roles for staging

# Example Custom Role:
# module "example_custom_role" {
#   source = "../modules/iam/custom_role"
#
#   project_id  = var.project_id
#   role_id     = "stagingCustomRole"
#   title       = "Staging Custom Role"
#   description = "Custom role for staging environment"
#
#   permissions = [
#     "storage.buckets.get",
#     "storage.buckets.list",
#     "storage.objects.get",
#     "storage.objects.list",
#   ]
# }
