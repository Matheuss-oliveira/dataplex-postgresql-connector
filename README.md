# Metadata connector from PostgreSQL to Google Dataplex Catalog

This project implements a managed pyspark job that fetchs metadata from postgreSQL instances and injects into the Google Cloud Dataplex Catalog Tool. The [existing framework](https://cloud.google.com/dataplex/docs/managed-connectivity-overview) from Google Cloud documentation was used as base for it.

This project was helped by @danielholgate which has developed similar connectors available on this repo [this repo](https://github.com/danielholgate/dataplex-catalog-connectors/tree/main/managed-connectivity/postgresql-connector). Eventually both projects might be merged.  

This project contains:
- The connector itself, which consist into a Python/Pyspark application, usable by a CLI, that query a PostgreSQL instance, transform data items into Dataplex import format and save it on a Google Cloud bucket.
- Dockerfile and a build/push script, to pack the connector into an image and push it to a Google Cloud artifact Registry
- Terraform files to deploy the infrastructure need to automate the execution of the connector and importation of the data to the Dataplex catalog in a Google Cloud environment. 
- Scripts to run parts of the execution flow manually (locally or remotely) 

# Some pre-requisites depending on the type of execution
- Docker and Terraform installed
- A GCP project (to host secrets and bucket)
- Terminal authenticated with [Google ADC credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc). Execution on the GCP terminal can simplify the process
- A user with the adequate roles/permissions (check the [main.tf](terraform/main.tf) for more details)
- Python 3.11 

# Creating a fully cloud infra for the connector execution
- Clone and enter this repository:
```bash
git clone https://github.com/Matheuss-oliveira/dataplex-postgresql-connector
cd dataplex-postgresql-connector
```

- Update the variables on the files: [terraform.tfvars](./terraform/terraform.tfvars), [workflow_args.json](./terraform/files/workflow_args.json)

- Enter the terraform folder and run the terraform commands
```bash
cd terraform
terraform init
terraform apply # confirm with "Yes"
```

- Due to some Terraform inconsistencies, the full deploy might present errors and you might need to enable the following APIs manually on the GCP console:
  - iam.googleapis.com
  - cloudresourcemanager.googleapis.com
  - compute.googleapis.com
  - serviceusage.googleapis.com
  - dataplex.googleapis.com

After enabling them, execute the **terraform apply** again

- Define the necessary variables
```bash
PROJECT_ID=dataplex-cni-3434 # Your project id 
LOCATION_ID=us-central1 # The region to store the artifact
IMAGE=postgresql-pyspark # The image name
DOCKER_REPO=dataplex-connectors # Artifact registry docker repository
```

- Build and push the Docker image
```bash
REPO_IMAGE=${LOCATION_ID}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO}/${IMAGE}
gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker ${LOCATION_ID}-docker.pkg.dev

docker build . -t ${REPO_IMAGE}
docker push "${REPO_IMAGE}"
```

- On the **Secret Manager** of your console, inside the secret container created by the terraform, insert the DB password as a new secret version

At this moment you will have
- The container on the Registry Artifact
- A workflow job defined to run the container and import data to dataplex
- A cloud scheduler that will trigger the workflow job according to a cron definition
- All the supporting infra for the whole process (network, subnet, nat, router, buckets, secrets, registry, apis, permissions, dataplex entities, etc...)


### Details on the terraform script
- Simplifications
  - This project is using the same service account for different part of the process (push to artifact, running workflow, creating resources, etc...). It's possible to separate the process by detailing more the parameters and defining the roles/permissions on the terraform files
  - I'm also using the same buckets to store job dependencies, metadata staging files, etc... More segregation is possible
  - It's possible to have a bucket holding the jars dependencies (postresql driver), but in this project the container is downloading. This was done to simplify the architecture
  - The same region and project is being used for all the process. 
  - Some jobs, process and definitions are being set with default values (e.g.: job id, batch id etc...) 



# Running the PySpark and triggering the dataplex locally  
- Clone and enter this repository:
```bash
git clone https://github.com/Matheuss-oliveira/dataplex-postgresql-connector
cd dataplex-postgresql-connector
```

- Install the dependencies
```bash
pip install -r requirements.txt
```

- Update the parameters for your 
```bash
PROJECT_ID=dataplex-cni-3434 # Project used to build dataplex entries/aspects ids
LOCATION_ID=us-central1 # Your Dataplex Catalog entities location
OUTPUT_FOLDER=output_folder # Folder on GCP bucket where the metadata will be stored
OUTPUT_BUCKET=bucket-test-3434 # Bucket on GCP where the metadata will be stored

TARGET_ENTRY_GROUP=postgresql-entry-group # Dataplex entry group that will store the generated entries

DB_HOST=repulsively-volcanic-goldfinch.data-1.use1.tembo.io # Your DB server address 
DB_PORT=5432 # Your DB port
DB_DATABASE=postgres # Your DB database 
DB_USER=postgres # DB user with permissions to read the metadata
DB_PASSWORD_SECRET=dataplex-postgresql-connector-secret # The google secret id. The actual password will be retrieved from what is stored in this resource
```

- On the **Secret Manager** of your console, inside the secret container created by the terraform, insert the DB password as a new secret version
  - It's possible to bypass the use of this cloud resource by updating the **get_password** function on **secret_manager.py** so it returns the password directly. It can be useful for testing/debugging.

- Create the **Google Cloud Storage Bucket** and **folder** that will be used as output

- Download the PostgreSQL JDBC Driver and save it on the root with the name **postgresql.jar**
```bash
wget https://jdbc.postgresql.org/download/postgresql-42.7.5.jar -O postgresql.jar
```

-  Execute the connector
```bash
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
```
At this moment the generated output is available locally and uploaded to the defined bucket/folder

- Execute the dataplex import job
```bash
DATAPLEX_API=dataplex.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}
alias gcurl='curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json"'

gcurl https://"${DATAPLEX_API}"/metadataJobs -d "$(cat <<EOF
{
  "type": "IMPORT",
  "import_spec": {
    "source_storage_uri": "gs://${OUTPUT_BUCKET}/${OUTPUT_FOLDER}/",
    "entry_sync_mode": "FULL",
    "aspect_sync_mode": "INCREMENTAL",
    "scope": {
      "entry_groups": ["projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryGroups/postgresql-entry-group"],
      "entry_types": [
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-instance",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-database",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-table",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-view"],

      "aspect_types": [
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-instance",
        "projects/dataplex-types/locations/global/aspectTypes/schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-database",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-table",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-view"],
      },
    },
  }
EOF
)"
```
At this moment the data will be available on the GCP dataplex catalog


## Building and executing the connector on cloud, with manual triggers

- Define the necessary variables
```bash
PROJECT_ID=dataplex-cni-3434 # Your project id 
LOCATION_ID=us-central1 # The region to store the artifact
IMAGE=postgresql-pyspark # The image name
DOCKER_REPO=dataplex-connectors # The GCP artifact registry docker repo name
OUTPUT_BUCKET=bucket-test-3434 # Bucket on GCP where the metadata will be stored
OUTPUT_FOLDER=output_folder # Folder on GCP bucket where the metadata will be stored
NETWORK_NAME=default "Your GCP network"
TARGET_ENTRY_GROUP=postgresql-entry-group # Dataplex entry group that will store the generated entries

DB_HOST=repulsively-volcanic-goldfinch.data-1.use1.tembo.io # Your DB server address 
DB_PORT=5432 # Your DB port
DB_DATABASE=postgres # Your DB database 
DB_USER=postgres # DB user with permissions to read the metadata
DB_PASSWORD_SECRET=dataplex-postgresql-connector-secret # The google secret id. The actual password will be retrieved from what is stored in this resource
```



- Build and push the docker image
```bash 
REPO_IMAGE=${LOCATION_ID}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO}/${IMAGE}

gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker ${LOCATION_ID}-docker.pkg.dev

docker build . -t ${REPO_IMAGE}
docker push "${REPO_IMAGE}"
```

- Execute the image using a dataproc serverless job
```bash
gcloud dataproc batches submit pyspark \
    --project=${PROJECT_ID} \
    --region=${LOCATION_ID} \
    --deps-bucket=${OUTPUT_BUCKET} \
    --container-image=${REPO_IMAGE} \
    --network=${NETWORK_NAME} \
    main.py \
--  --target_project_id ${PROJECT_ID} \
    --target_location_id ${LOCATION_ID} \
    --target_entry_group_id ${TARGET_ENTRY_GROUP} \
    --host ${DB_HOST} \
    --port ${DB_PORT} \
    --user ${DB_USER} \
    --password-secret ${DB_PASSWORD_SECRET} \
    --database ${DB_DATABASE} \
    --output_bucket ${OUTPUT_BUCKET} \
    --output_folder ${OUTPUT_FOLDER}
```
At this moment the generated output is available locally and uploaded to the defined bucket/folder

- Execute the dataplex import job
```bash
DATAPLEX_API=dataplex.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}
alias gcurl='curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json"'

gcurl https://"${DATAPLEX_API}"/metadataJobs -d "$(cat <<EOF
{
  "type": "IMPORT",
  "import_spec": {
    "source_storage_uri": "gs://${OUTPUT_BUCKET}/${OUTPUT_FOLDER}/",
    "entry_sync_mode": "FULL",
    "aspect_sync_mode": "INCREMENTAL",
    "scope": {
      "entry_groups": ["projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryGroups/postgresql-entry-group"],
      "entry_types": [
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-instance",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-database",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-table",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/entryTypes/postgresql-view"],

      "aspect_types": [
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-instance",
        "projects/dataplex-types/locations/global/aspectTypes/schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-database",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-schema",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-table",
        "projects/${PROJECT_ID}/locations/${LOCATION_ID}/aspectTypes/postgresql-view"],
      },
    },
  }
EOF
)"
```
At this moment the data will be available on the GCP dataplex catalog

