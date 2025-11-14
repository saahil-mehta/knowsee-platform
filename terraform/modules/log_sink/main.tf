resource "google_bigquery_dataset" "dataset" {
  project                    = var.project_id
  dataset_id                 = var.dataset_id
  friendly_name              = var.dataset_friendly_name
  location                   = var.location
  delete_contents_on_destroy = false
}

resource "google_logging_project_sink" "sink" {
  project     = var.project_id
  name        = var.sink_name
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.dataset.dataset_id}"
  filter      = var.filter

  bigquery_options {
    use_partitioned_tables = var.use_partitioned_tables
  }

  unique_writer_identity = true
}

resource "google_project_iam_member" "bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_project_sink.sink.writer_identity
}
