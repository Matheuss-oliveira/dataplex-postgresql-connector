variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
  default     = "lab-xwf-cni" # Change this to your actual project ID
}

variable "region" {
  type        = string
  description = "The Google Cloud region to deploy resources in"
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  description = "The name of the Google Cloud Storage bucket"
  default     = "test-terraform-bucket-343" # Change this to your desired bucket name
}

variable "entry_group" {
  type        = string
}

variable "aspect_types" {
  type = list(string)
  description = "List of Dataplex Aspect Type IDs to create"
  default = [
    "postgresql-database",
    "postgresql-instance",
    "postgresql-schema",
    "postgresql-table",
    "postgresql-view"
  ]
}

variable "entry_types" {
  type = list(string)
  description = "List of Dataplex Entry Type IDs to create"
  default = [
    "postgresql-database",
    "postgresql-instance",
    "postgresql-schema",
    "postgresql-table",
    "postgresql-view"
  ]
}
