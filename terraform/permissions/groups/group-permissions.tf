# Group-based IAM permissions for staging

# Example Group-based Project IAM:
# module "group_permissions" {
#   source = "../modules/iam/project"
#
#   project_id = var.project_id
#
#   bindings = {
#     "roles/viewer" = [
#       "group:staging-viewers@example.com",
#     ]
#     "roles/editor" = [
#       "group:staging-developers@example.com",
#     ]
#     "roles/owner" = [
#       "group:staging-admins@example.com",
#     ]
#   }
# }
