#https://cloud.google.com/sdk/gcloud/reference/dataproc/batches/submit
# subnet with private google access must be enabled (default meyabe)
# todo maybe service account, batch ID, others

echo gcloud dataproc batches submit pyspark \
    --project=${PROJECT_ID} \
    --region=${REGION} \
    --deps-bucket=${DEPS_BUCKET} \
    --container-image=${REPO_IMAGE} \
    --jars=${SPARK_EXTRA_JARS_DIR} \
    --network=${NETWORK_NAME} \
    main.py \
--  --target_project_id ${PROJECT_ID} \
    --target_location_id ${REGION} \
    --target_entry_group_id ${TARGET_ENTRY_GROUP} \
    --port ${DB_HOST} \
    --port ${DB_PORT} \
    --user ${DB_USER} \
    --password-secret ${DB_PASSWORD_SECRET} \
    --database ${DB_DATABASE} \
    --output_bucket ${OUTPUT_BUCKET} \
    --output_folder ${OUTPUT_FOLDER}

gcloud dataproc batches submit pyspark \
  --project=dataplex-cni-3434 \
  --region=us-central1 \
  --jars=gs://bucket-test-3434/jars/postgresql-42.7.5.jar \
  --deps-bucket=bucket-test-3434 \
  --container-image=us-central1-docker.pkg.dev/dataplex-cni-3434/dataplex-connectors2/postgresql-pyspark \
  --network=default \
  main.py \
  -- \
  --target_project_id dataplex-cni-3434 \
  --target_location_id us-central1 \
  --target_entry_group_id postgresql-entry-group \
  --host repulsively-volcanic-goldfinch.data-1.use1.tembo.io \
  --port 5432 \
  --user postgres \
  --database postgres \
  --password-secret projects/73813454526/secrets/dataplexagent_postgres \
  --output_bucket bucket-test-3434 \
  --output_folder output_folder

