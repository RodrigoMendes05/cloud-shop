variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "allowed_role_arns" {
  description = "Lista de ARNs de IAM roles que podem usar a queue"
  type        = list(string)
}
