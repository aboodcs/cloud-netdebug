variable "name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID used by the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the EC2 instance will be created"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to the EC2 instance"
  type        = list(string)
}

variable "key_name" {
  description = "AWS key pair used for SSH access"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether the EC2 instance receives a public IP"
  type        = bool
}

variable "tags" {
  description = "Additional tags applied to the EC2 instance"
  type        = map(string)
  default     = {}
}