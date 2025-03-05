terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.19.0"  
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
  for_each = toset(var.api_services2)  

  service            = each.value
  disable_on_destroy = false
  project            = var.project_id
}

resource "google_project_service" "enabled_apis2" {
  for_each = toset(var.api_services2)  

  service            = each.value
  disable_on_destroy = false
  project            = var.project_id
}

resource "null_resource" "api_dependencies" {
  depends_on = [google_project_service.enabled_apis1, google_project_service.enabled_apis2]
}

resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_name

  replication {
    auto {}
  }
}

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

# NETWORK
resource "google_compute_network" "net" {
  name = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  network       = google_compute_network.net.id
  ip_cidr_range = "10.128.0.0/20"
  region        = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.net.name
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Workflow
resource "google_workflows_workflow" "dataplex_workflow" {
  name            = var.workflow_name
  region          = var.region
  service_account = google_service_account.dataplex_sa.email

  deletion_protection = false # set to "true" in production
  source_contents = file("files/workflow")
}

resource "google_cloud_scheduler_job" "job" {
  name             = var.scheduler_name
  schedule         = var.scheduler_value
  time_zone        = var.scheduler_tz
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.dataplex_workflow.id}/executions"
    body = base64encode(
      jsonencode({
        "argument" : file("files/workflow_args.json")
        "callLogLevel" : "CALL_LOG_LEVEL_UNSPECIFIED"
        }
    ))

    oauth_token {
      service_account_email = google_service_account.dataplex_sa.email}
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}


