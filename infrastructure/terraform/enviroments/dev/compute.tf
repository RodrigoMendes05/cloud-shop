# EC2 para o api-gateway (subnet pública)
module "ec2_gateway" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_web_id
  service_name      = "gateway"
  ami_id            = var.ami_id
}

# EC2 para o user-service (subnet pública por agora)
module "ec2_user" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  service_name      = "user"
  ami_id            = var.ami_id
}

# EC2 para o product-service (subnet pública por agora)
module "ec2_product" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  service_name      = "product"
  ami_id            = var.ami_id
}

# EC2 para o order-service (subnet pública por agora)
module "ec2_order" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  service_name      = "order"
  ami_id            = var.ami_id
}

# EC2 para o notification-service (novo — Day 7)
module "ec2_notification" {
  source = "../../modules/compute"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_app_id
  service_name      = "notification"
  ami_id            = var.ami_id
}
