docker run -it \
    -e target_project_id=${PROJECT_ID} \
    -e target_location_id=${LOCATION_ID} \
    -e target_entry_group_id=${TARGET_ENTRY_GROUP} \
    -e host=${DB_HOST} \
    -e port=${DB_PORT} \
    -e user=${DB_USER} \
    -e password-secret=${DB_PASSWORD_SECRET} \
    -e database=${DB_DATABASE} \
    -e output_bucket=${OUTPUT_BUCKET} \
    -e output_folder=${OUTPUT_FOLDER}
    ${IMAGE}



python main.py \
    --target_project_id=${PROJECT_ID} \
    --target_location_id=${LOCATION_ID} \
    --target_entry_group_id=${TARGET_ENTRY_GROUP} \
    --host=${DB_HOST} \
    --port=${DB_PORT} \
    --user=${DB_USER} \
    --password-secret=${DB_PASSWORD_SECRET} \
    --database=${DB_DATABASE} \
    --output_bucket=${OUTPUT_BUCKET} \
    --output_folder=${OUTPUT_FOLDER}

python main.py \
  --target_project_id=dataplex-cni-3434 \
  --target_location_id=us-central1 \
  --target_entry_group_id=postgresql-entry-group \
  --host=repulsively-volcanic-goldfinch.data-1.use1.tembo.io \
  --port=5432 \
  --user=postgres \
  --password-secret=dataplex-postgresql-connector-secret \
  --database=postgres \
  --output_bucket=bucket-test-3434 \
  --output_folder=output_folder
