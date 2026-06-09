module "database" {
  source = "../../modules/database"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.vpc.sg_db_id
  db_password        = var.db_password
}