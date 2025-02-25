"""A module to get a password from the Secret Manager."""
from google.cloud import secretmanager


def get_password(project_id, secret: str) -> str:
    """Gets password from a GCP service."""
    client = secretmanager.SecretManagerServiceClient()
    secret_path = f"projects/{project_id}/secrets/{secret}/versions/latest"

    response = client.access_secret_version(request={"name": secret_path})
    return response.payload.data.decode("UTF-8")
