output "data_store_id" {
  description = "ID of the created data store"
  value       = google_discovery_engine_data_store.data_store.data_store_id
}

output "data_store_name" {
  description = "Full resource name of the data store"
  value       = google_discovery_engine_data_store.data_store.name
}

output "data_store_location" {
  description = "Location of the data store"
  value       = google_discovery_engine_data_store.data_store.location
}

output "search_engine_id" {
  description = "ID of the search engine (if created)"
  value       = var.create_search_engine ? google_discovery_engine_search_engine.search_engine[0].engine_id : null
}

output "search_engine_name" {
  description = "Full resource name of the search engine (if created)"
  value       = var.create_search_engine ? google_discovery_engine_search_engine.search_engine[0].name : null
}
