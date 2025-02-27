PROJECT_ID=dataplex-cni-3434
LOCATION_ID=us-central1
OUTPUT_FOLDER=output_folder
OUTPUT_BUCKET=bucket-test-3434
NETWORK_NAME=default

TARGET_ENTRY_GROUP=postgresql-entry-group

IMAGE=postgreslq-pyspark
DOCKER_REPO=dataplex-connectors
REPO_IMAGE=${LOCATION_ID}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO}/${IMAGE}
SERVICE_ACCOUNT_NAME=dataplex-appscript@lab-xwf-cni.iam.gserviceaccount.com

DB_HOST=repulsively-volcanic-goldfinch.data-1.use1.tembo.io
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD_SECRET=dataplex-postgresql-connector-secret
DB_DATABASE=postgres