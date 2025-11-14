terraform {
  backend "gcs" {
    bucket = "terraform-knowsee-cicd"
    prefix = "terraform/state"
  }
}
