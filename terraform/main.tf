terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.19.0"  # Or the latest version you want to use
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}


resource "google_storage_bucket" "my_bucket" {
  name                    = var.bucket_name
  location                = var.region
  force_destroy           = true # important if you want to be able to delete the bucket easily with terraform destroy
  storage_class           = "STANDARD"
  uniform_bucket_level_access = true
}


# DATAPLEX
resource "google_dataplex_aspect_type" "aspect_type" {
  for_each       = toset(var.aspect_types)
  aspect_type_id = each.key
  project        = var.project_id
  location       = var.region
  metadata_template = jsonencode({
  name         = "empty-template"
  type         = "record"
  recordFields = []
  })
}

resource "google_dataplex_entry_type" "entry_type" {
  for_each      = toset(var.entry_types)
  entry_type_id = each.key
  project       = var.project_id
  location      = var.region
}


resource "google_dataplex_entry_group" "entry_group" {
  entry_group_id = var.entry_group
  project = var.project_id
  location = var.region
}


resource "google_artifact_registry_repository" "artifact_registry" {
  provider      = google
  repository_id = var.artifact_registry_id
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id
}

# APIS
resource "google_project_service" "enabled_apis" {
  for_each = toset(var.api_services)  # Use toset to ensure uniqueness

  service            = each.value
  disable_on_destroy = false
  project            = var.project_id
}

# To ensure all APIs are enabled before other resources are created:
resource "null_resource" "api_dependencies" {
  depends_on = [google_project_service.enabled_apis]
}