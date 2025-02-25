gcurl https://${DATAPLEX_API}/metadataJobs -d "$(cat <<EOF
{
  "type": "IMPORT",
  "import_spec": {
    "source_storage_uri": "gs://${OUTPUT_BUCKET}/${OUTPUT_FOLDER}/",
    "entry_sync_mode": "FULL",
    "aspect_sync_mode": "INCREMENTAL",
    "scope": {
      "entry_groups": ["projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryGroups/${SOURCE}-entry-group2"],
      "entry_types": [
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/${SOURCE}2-instance",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/${SOURCE}2-database",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/${SOURCE}2-schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/${SOURCE}2-table",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/${SOURCE}2-view"],

      "aspect_types": [
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/${SOURCE}2-instance",
        "projects/dataplex-types/locations/global/aspectTypes/schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/${SOURCE}2-database",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/${SOURCE}2-schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/${SOURCE}2-table",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/${SOURCE}2-view"],
      },
    },
  }
EOF
)"