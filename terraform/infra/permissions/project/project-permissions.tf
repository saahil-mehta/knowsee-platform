/*
  Project-level IAM bindings for knowsee platform
  Keep this file updated as we manage roles via Terraform.
*/

locals {
  project_iam_bindings = {

    # ============================================================================
    # PROJECT VIEWERS
    # ============================================================================

    "roles/viewer" = {
      members = [
        "group:developers@knowsee.co.uk"
      ]
    }

  }
}
