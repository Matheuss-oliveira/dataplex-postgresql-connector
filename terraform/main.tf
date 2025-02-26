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
resource "google_project_service" "enabled_apis1" {
  for_each = toset(var.api_services2)  # Use toset to ensure uniqueness

  service            = each.value
  disable_on_destroy = false
  project            = var.project_id
}

resource "google_project_service" "enabled_apis2" {
  for_each = toset(var.api_services2)  # Use toset to ensure uniqueness

  service            = each.value
  disable_on_destroy = false
  project            = var.project_id
}

# To ensure all APIs are enabled before other resources are created:
resource "null_resource" "api_dependencies" {
  depends_on = [google_project_service.enabled_apis1, google_project_service.enabled_apis2]
}

# SECRET
resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_name

  replication {
    auto {}
  }
}

# SERVICE ACCOUNT

resource "google_service_account" "dataplex_sa" {
  account_id   = var.service_account_id
  display_name = "Dataplex Service Account"
}

resource "google_project_iam_member" "dataplex_sa_roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.dataplex_sa.email}"
  depends_on = [google_service_account.dataplex_sa]
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = var.secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dataplex_sa.email}"
  depends_on = [google_service_account.dataplex_sa, google_project_iam_member.dataplex_sa_roles]
}

resource "google_storage_bucket_iam_member" "storage_object_user" {
  bucket   = var.bucket_name
  role     = "roles/storage.objectUser"
  member   = "serviceAccount:${google_service_account.dataplex_sa.email}"
  depends_on = [google_service_account.dataplex_sa, google_project_iam_member.dataplex_sa_roles, google_storage_bucket.my_bucket]
}

resource "google_artifact_registry_repository_iam_member" "artifact_registry_reader" {
  location   = var.region
  project    = var.project_id
  repository = var.artifact_registry_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.dataplex_sa.email}"
  depends_on = [google_service_account.dataplex_sa, google_project_iam_member.dataplex_sa_roles, google_artifact_registry_repository.artifact_registry]
}

resource "google_secret_manager_regional_secret" "secret-basic" {
  secret_id = var.secret_name
  location = var.region
}

resource "google_secret_manager_regional_secret_version" "regional_secret_version_basic" {
  secret = google_secret_manager_regional_secret.secret-basic.id
  secret_data = "1osUtXYHsvHnkN7g" # TODO this is unsafe for prod, use for testing only
}
