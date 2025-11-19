/*
  Project-level IAM bindings for knowsee platform
  Keep this file updated as we manage roles via Terraform.
*/

locals {
  project_iam_bindings = {

    # ============================================================================
    # PROJECT EDITORS
    # ============================================================================

    "roles/editor" = {
      members = [
        "user:m.kanaujia@knowsee.co.uk"
      ]
    }

  }
}
