variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "shop"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
variable "ami_id" {
  type    = string
  default = "ami-0c8ab82f51d47e1be" # Amazon Linux 2023 eu-central-1
}
