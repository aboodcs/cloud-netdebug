## ─── OCI API Credentials ─────────────────────────────────────────────────────

variable "user_ocid" {
  description = "OCID of the OCI user for API authentication"
  type        = string
  sensitive   = true
}

variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API signing key"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Absolute path to the OCI API private key (.pem)"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region where resources will be created"
  type        = string
  default     = "me-jeddah-1"
}

## ─── Compartment ─────────────────────────────────────────────────────────────

variable "compartment_id" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

## ─── Resource Metadata Tags ──────────────────────────────────────────────────

variable "project_name" {
  description = "Project name used in resource display names and freeform tags"
  type        = string
  default     = "oci-netdebug"
}

variable "environment" {
  description = "Environment name used in freeform tags"
  type        = string
  default     = "Development"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "abdulrehman-yahya"
}

variable "managed_by" {
  description = "Tool managing the infrastructure"
  type        = string
  default     = "Terraform"
}

variable "cloud_provider" {
  description = "Cloud provider used by this environment"
  type        = string
  default     = "OCI"
}

## ─── Networking ──────────────────────────────────────────────────────────────

variable "cidr_blocks" {
  description = "CIDR blocks for the VCN"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_cidr" {
  description = "CIDR block used by the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block used by the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}
## ─── Access Control ──────────────────────────────────────────────────────────

variable "allowed_ssh_cidr" {
  description = "Public IP CIDR allowed to SSH into the instance"
  type        = string
}

## ─── Compute ─────────────────────────────────────────────────────────────────

variable "instance_shape" {
  description = "OCI Compute shape used for the development instance"
  type        = string
  default     = "VM.Standard.E2.1.flex"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used to access the instance"
  type        = string
}