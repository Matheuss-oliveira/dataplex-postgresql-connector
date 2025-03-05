variable "project_id" {
  type        = string
}

variable "region" {
  type        = string
}

variable "bucket_name" {
  type        = string
}

variable "entry_group" {
  type        = string
}

variable "aspect_types" {
  type = list(string)
}

variable "entry_types" {
  type = list(string)
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

variable "network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "router_name" {
  type = string
}

variable "nat_name" {
  type = string
}

variable "workflow_name" {
  type = string
}
variable "scheduler_name" {
  type = string
}

variable "scheduler_value" {
  type = string
}

variable "scheduler_tz" {
  type = string
}
