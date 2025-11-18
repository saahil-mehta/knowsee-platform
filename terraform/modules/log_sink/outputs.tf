output "dataset_id" {
  description = "ID of the BigQuery dataset"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "dataset_name" {
  description = "Full resource name of the BigQuery dataset"
  value       = google_bigquery_dataset.dataset.id
}

output "sink_name" {
  description = "Name of the log sink"
  value       = google_logging_project_sink.sink.name
}

output "sink_writer_identity" {
  description = "Writer identity of the log sink"
  value       = google_logging_project_sink.sink.writer_identity
}
