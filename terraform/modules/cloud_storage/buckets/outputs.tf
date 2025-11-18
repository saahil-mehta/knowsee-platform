output "name" {
  description = "Name of the storage bucket"
  value       = google_storage_bucket.bucket.name
}

output "url" {
  description = "URL of the storage bucket"
  value       = google_storage_bucket.bucket.url
}

output "self_link" {
  description = "Self link of the storage bucket"
  value       = google_storage_bucket.bucket.self_link
}

output "location" {
  description = "Location of the storage bucket"
  value       = google_storage_bucket.bucket.location
}
