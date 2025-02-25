#!/bin/bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

### THE TERMINAL HAD ITS SESSION RE-INITIALIZED. LOAD THE VARIABLES AGAIN BEFORE CONTINUING ###
docker build -t "${IMAGE}" .

# Tag and push to GCP container registry
gcloud config set project ${PROJECT}
gcloud auth configure-docker ${LOCATION_ID}-docker.pkg.dev
docker tag "${IMAGE}" "${REPO_IMAGE}"
docker push "${REPO_IMAGE}"

