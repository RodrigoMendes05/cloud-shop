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
