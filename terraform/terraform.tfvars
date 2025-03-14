project_id  = "dataplex-cni-3434"
bucket_name = "bucket-test-3434"
entry_group = "postgresql-entry-group"
region = "us-central1"
service_account_id = "dataplex-connector-sa"
aspect_types = [
    "postgresql-database",
    "postgresql-instance",
    "postgresql-schema",
    "postgresql-table",
    "postgresql-view"
  ]
entry_types = [
    "postgresql-database",
    "postgresql-instance",
    "postgresql-schema",
    "postgresql-table",
    "postgresql-view"
  ]
artifact_registry_id = "dataplex-connectors"

api_services1 = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "serviceusage.googleapis.com",
    "dataplex.googleapis.com",
]

api_services2 = [
    "dataproc.googleapis.com",
    "workflows.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com",
    "logging.googleapis.com"
]

secret_name = "dataplex-postgresql-connector-secret"

roles = [
    "roles/logging.logWriter",
    "roles/dataplex.entryGroupOwner",
    "roles/dataplex.entryOwner",
    "roles/dataplex.aspectTypeOwner",
    "roles/dataplex.metadataJobOwner",
    "roles/dataplex.catalogEditor",
    "roles/dataproc.editor",
    "roles/dataproc.worker",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectUser",
    "roles/artifactregistry.reader",
    "roles/artifactregistry.writer",
    "roles/workflows.invoker",
    "roles/dataproc.editor",
    "roles/iam.serviceAccountUser", # Apparently we need this even if we use the same sa in workflow/dataproc
]

network_name = "default2"
subnet_name = "default2"
router_name = "router-nat"
nat_name = "nat"

workflow_name = "workflow_name"
scheduler_name = "scheduler"
scheduler_value = "0 0 * * *"
scheduler_tz = "America/New_York"