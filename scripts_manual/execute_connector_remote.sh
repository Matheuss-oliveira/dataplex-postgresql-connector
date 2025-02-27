gcloud dataproc batches submit pyspark \
    --project=${PROJECT_ID} \
    --region=${REGION} \
    --deps-bucket=${OUTPUT_BUCKET} \
    --container-image=${REPO_IMAGE} \
    --network=${NETWORK_NAME} \
    main.py \
--  --target_project_id ${PROJECT_ID} \
    --target_location_id ${REGION} \
    --target_entry_group_id ${TARGET_ENTRY_GROUP} \
    --host ${DB_HOST} \
    --port ${DB_PORT} \
    --user ${DB_USER} \
    --password-secret ${DB_PASSWORD_SECRET} \
    --database ${DB_DATABASE} \
    --output_bucket ${OUTPUT_BUCKET} \
    --output_folder ${OUTPUT_FOLDER}