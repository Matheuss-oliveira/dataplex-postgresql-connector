PROJECT_ID=lab-xwf-cni
LOCATION_ID=us-central1
DATAPLEX_API=dataplex.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION_ID
alias gcurl='curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json"'


gcurl https://${DATAPLEX_API}/metadataJobs?metadata_job_id="connect-dataplex-job" -d "$(cat <<EOF
{
  "type": "IMPORT",
  "import_spec": {
    "source_storage_uri": "gs://dataplex-connector-bucket/dataplex-connector-folder/",
    "entry_sync_mode": "FULL",
    "aspect_sync_mode": "INCREMENTAL",
    "scope": {
      "entry_groups": ["projects/lab-xwf-cni/locations/us-central1/entryGroups/postgresql-entry-group"],
      "entry_types": [
        "projects/lab-xwf-cni/locations/us-central1/entryTypes/postgresql-instance",
        "projects/lab-xwf-cni/locations/us-central1/entryTypes/postgresql-database",
        "projects/lab-xwf-cni/locations/us-central1/entryTypes/postgresql-schema",
        "projects/lab-xwf-cni/locations/us-central1/entryTypes/postgresql-table",
        "projects/lab-xwf-cni/locations/us-central1/entryTypes/postgresql-view"],

      "aspect_types": [
        "projects/lab-xwf-cni/locations/us-central1/aspectTypes/postgresql-instance",
        "projects/dataplex-types/locations/global/aspectTypes/schema",
        "projects/lab-xwf-cni/locations/us-central1/aspectTypes/postgresql-database",
        "projects/lab-xwf-cni/locations/us-central1/aspectTypes/postgresql-schema",
        "projects/lab-xwf-cni/locations/us-central1/aspectTypes/postgresql-table",
        "projects/lab-xwf-cni/locations/us-central1/aspectTypes/postgresql-view"],
      },
    },
  }
EOF
)"