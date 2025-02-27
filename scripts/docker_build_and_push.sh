PROJECT_ID=dataplex-cni-3434
LOCATION_ID=us-central1
IMAGE=postgresql-pyspark
DOCKER_REPO=dataplex-connectors
REPO_IMAGE=${LOCATION_ID}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO}/${IMAGE}

gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker ${LOCATION_ID}-docker.pkg.dev

docker build . -t ${REPO_IMAGE}
docker push "${REPO_IMAGE}"