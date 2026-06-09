output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "ec2_gateway_ip" {
  value = module.ec2_gateway.public_ip
}

output "ec2_user_ip" {
  value = module.ec2_user.public_ip
}

output "ec2_product_ip" {
  value = module.ec2_product.public_ip
}

output "ec2_order_ip" {
  value = module.ec2_order.public_ip
}

output "db_endpoint" {
  value = module.database.db_endpoint
}
