# 1. manual_exec_part1.sh
PROJECT_ID=dataplex-cni-3434
LOCATION_ID=us-central1

# 2. manual_exec_part2.sh
SOURCE=postgresql

# 3. push_to_registry.sh
IMAGE=${SOURCE}-pyspark
PROJECT=${PROJECT_ID}
DOCKER_REPO=dataplex-connectors2
REPO_IMAGE=us-central1-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO}/${IMAGE}

# Dockerfile
SOURCE_JAR_PATH=src/postgresql-42.7.5.jar
SPARK_EXTRA_JARS_DIR=gs://bucket-test-3434/jars/postgresql-42.7.5.jar

# 4. run_connector.sh
REGION=${LOCATION_ID}
BATCH_ID=my-batch-id
CUSTOM_CONTAINER_IMAGE=${REPO_IMAGE}
SERVICE_ACCOUNT_NAME=dataplex-appscript@lab-xwf-cni.iam.gserviceaccount.com
PATH_TO_JAR_FILES=/opt/spark/jars/
DEPS_BUCKET=bucket-test-3434

NETWORK_NAME=default
BATCH_ID=0011


TARGET_ENTRY_GROUP=postgresql-entry-group
# DB
DB_HOST=repulsively-volcanic-goldfinch.data-1.use1.tembo.io
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD_SECRET=projects/73813454526/secrets/dataplexagent_postgres
DB_DATABASE=postgres
OUTPUT_BUCKET=output-bucket
OUTPUT_FOLDER=output_folder
