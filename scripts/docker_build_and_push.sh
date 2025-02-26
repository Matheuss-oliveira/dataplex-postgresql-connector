docker build -t "${IMAGE}" .

gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker ${LOCATION_ID}-docker.pkg.dev
docker tag "${IMAGE}" "${REPO_IMAGE}"
docker push "${REPO_IMAGE}"

