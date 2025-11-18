resource "google_iam_workload_identity_pool" "pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_display_name
  description               = var.pool_description
  disabled                  = var.pool_disabled
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_display_name
  description                        = var.provider_description
  disabled                           = var.provider_disabled

  oidc {
    issuer_uri = var.issuer_uri
  }

  attribute_mapping   = var.attribute_mapping
  attribute_condition = var.attribute_condition
}

resource "google_service_account_iam_member" "workload_identity_user" {
  count = var.service_account_email != null ? 1 : 0

  service_account_id = var.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/${var.repository_owner}/${var.repository_name}"
}

resource "google_service_account_iam_member" "token_creator" {
  count = var.service_account_email != null && var.grant_token_creator ? 1 : 0

  service_account_id = var.service_account_id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/${var.repository_owner}/${var.repository_name}"
}
