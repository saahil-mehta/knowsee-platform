resource "google_discovery_engine_data_store" "data_store" {
  location                    = var.location
  project                     = var.project_id
  data_store_id               = var.data_store_id
  display_name                = var.display_name
  industry_vertical           = var.industry_vertical
  content_config              = var.content_config
  solution_types              = var.solution_types
  create_advanced_site_search = var.create_advanced_site_search
}

resource "google_discovery_engine_search_engine" "search_engine" {
  count = var.create_search_engine ? 1 : 0

  project        = var.project_id
  engine_id      = var.search_engine_id
  collection_id  = var.collection_id
  location       = google_discovery_engine_data_store.data_store.location
  display_name   = var.search_engine_display_name
  data_store_ids = [google_discovery_engine_data_store.data_store.data_store_id]

  search_engine_config {
    search_tier = var.search_tier
  }
}
