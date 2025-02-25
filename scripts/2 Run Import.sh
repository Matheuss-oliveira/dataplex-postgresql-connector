gcurl https://${DATAPLEX_API}/metadataJobs -d "$(cat <<EOF
{
  "type": "IMPORT",
  "import_spec": {
    "source_storage_uri": "gs://${OUTPUT_BUCKET}/${OUTPUT_FOLDER}/",
    "entry_sync_mode": "FULL",
    "aspect_sync_mode": "INCREMENTAL",
    "scope": {
      "entry_groups": ["projects/${PROJECT_ID}/locations/${REGION}/entryGroups/${SOURCE}-entry-group"],
      "entry_types": [
        "projects/${PROJECT_ID}/locations/${REGION}/entryTypes/${SOURCE}-instance",
        "projects/${PROJECT_ID}/locations/${REGION}/entryTypes/${SOURCE}-database",
        "projects/${PROJECT_ID}/locations/${REGION}/entryTypes/${SOURCE}-schema",
        "projects/${PROJECT_ID}/locations/${REGION}/entryTypes/${SOURCE}-table",
        "projects/${PROJECT_ID}/locations/${REGION}/entryTypes/${SOURCE}-view"],

      "aspect_types": [
        "projects/${PROJECT_ID}/locations/${REGION}/aspectTypes/${SOURCE}-instance",
        "projects/dataplex-types/locations/global/aspectTypes/schema",
        "projects/${PROJECT_ID}/locations/${REGION}/aspectTypes/${SOURCE}-database",
        "projects/${PROJECT_ID}/locations/${REGION}/aspectTypes/${SOURCE}-schema",
        "projects/${PROJECT_ID}/locations/${REGION}/aspectTypes/${SOURCE}-table",
        "projects/${PROJECT_ID}/locations/${REGION}/aspectTypes/${SOURCE}-view"],
      },
    },
  }
EOF
)"