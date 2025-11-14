output "required_apis" {
  description = "List of required GCP APIs for CICD project"
  value = [
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
}
