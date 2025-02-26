variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
}

variable "region" {
  type        = string
  description = "The Google Cloud region to deploy resources in"
}

variable "bucket_name" {
  type        = string
  description = "The name of the Google Cloud Storage bucket"
}

variable "entry_group" {
  type        = string
}

variable "aspect_types" {
  type = list(string)
  description = "List of Dataplex Aspect Type IDs to create"
}

variable "entry_types" {
  type = list(string)
  description = "List of Dataplex Entry Type IDs to create"
}

variable "artifact_registry_id" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "api_services1" {
  type = list(string)
}
variable "api_services2" {
  type = list(string)
}

variable "secret_name" {
  type = string
}

variable "roles" {
  type = list(string)
}