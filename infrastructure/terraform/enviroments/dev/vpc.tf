module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
}
