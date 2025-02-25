docker run -it \
    -e target_project_id=lab-xwf-cni \
    -e target_location_id=us-central1 \
    -e target_entry_group_id=postgresql-entry-group \
    -e host=127.0.0.1 \
    -e port=5432 \
    -e user=postgres \
    -e password-secret=pass \
    -e database=postgres \
    -e output_bucket=dataplex-connector-bucket \
    -e output_folder=dataplex-connector-folder
    ${IMAGE}