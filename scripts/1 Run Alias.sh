DATAPLEX_API=dataplex.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION_ID
alias gcurl='curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json"'