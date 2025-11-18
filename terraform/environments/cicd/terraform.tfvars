# CICD Environment Configuration
project_id       = "your-cicd-project-id"
billing_project  = "your-cicd-project-id" # Usually same as project_id unless using shared billing
project_name     = "sagent"
resource_prefix  = "knowsee"
environment      = "cicd"
region           = "europe-west2"
repository_owner = "your-github-username"
repository_name  = "knowsee-platform"

labels = {
  environment = "cicd"
  managed_by  = "terraform"
  project     = "knowsee"
}
