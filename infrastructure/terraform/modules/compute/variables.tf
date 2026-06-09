variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  description = "Subnet where the EC2 will be placed"
  type        = string
}

variable "security_group_id" {
  description = "Security group to attach"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "service_name" {
  description = "Name of the service running on this instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2023)"
  type        = string
  default     = "ami-0e04bcbe83a83792e"
}
