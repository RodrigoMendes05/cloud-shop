# EC2 para o api-gateway (subnet pública)
module "ec2_gateway" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_web_id
  key_name          = "shop-dev-key"
  service_name      = "gateway"
}

# EC2 para o user-service (subnet privada)
module "ec2_user" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  key_name          = "shop-dev-key"
  service_name      = "user"
}

# EC2 para o product-service (subnet privada)
module "ec2_product" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  key_name          = "shop-dev-key"
  service_name      = "product"
}

# EC2 para o order-service (subnet privada)
module "ec2_order" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  key_name          = "shop-dev-key"
  service_name      = "order"
}