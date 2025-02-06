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
}

resource "google_dataplex_entry_type" "entry_type" {
  for_each      = toset(var.entry_types)
  entry_type_id = each.key
  project       = var.project_id
  location       = var.region
}


resource "google_dataplex_entry_group" "entry_group" {
  entry_group_id = var.entry_group
  project = var.project_id
  location = var.region
}