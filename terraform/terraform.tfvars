project_id  = "lab-xwf-cni"
bucket_name = "bucket-test-343"
entry_group = "postgresql-entry-group2"
aspect_types = [
    "postgresql2-database",
    "postgresql2-instance",
    "postgresql2-schema",
    "postgresql2-table",
    "postgresql2-view"
  ]
entry_types = [
    "postgresql2-database",
    "postgresql2-instance",
    "postgresql2-schema",
    "postgresql2-table",
    "postgresql2-view"
  ]
artifact_registry_id = "dataplex-connectors2"

api_services = [
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "workflows.googleapis.com",
    "artifactregistry.googleapis.com",
]