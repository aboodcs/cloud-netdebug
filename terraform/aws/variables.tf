variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "aws-netdebug"
}

variable "environment" {
  description = "Environment name used in resource tags"
  type        = string
  default     = "Development"
}

variable "managed_by" {
  description = "Tool managing the infrastructure"
  type        = string
  default     = "Terraform"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "abdulrehman-yahya"
}

variable "cloud_provider" {
  description = "Cloud provider used by this environment"
  type        = string
  default     = "AWS"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

## ─── Networking ──────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
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
  description = "Public IP CIDR allowed to SSH into admin-01"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 key pair name used for SSH access"
  type        = string
}

## ─── Compute ─────────────────────────────────────────────────────────────────

variable "admin_instance_type" {
  description = "EC2 instance type used by admin-01"
  type        = string
  default     = "t3.small"
}

variable "target_instance_type" {
  description = "EC2 instance type used by target-01"
  type        = string
  default     = "t3.small"
}

variable "admin_instance_name" {
  description = "Name of the public admin EC2 instance"
  type        = string
  default     = "aws-admin-01"
}

variable "target_instance_name" {
  description = "Name of the private target EC2 instance"
  type        = string
  default     = "aws-target-01"
}
variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for EC2 access"
  type        = string
}