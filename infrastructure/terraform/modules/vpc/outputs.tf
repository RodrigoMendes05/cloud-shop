output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "sg_web_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "sg_app_id" {
  description = "ID of the app security group"
  value       = aws_security_group.app.id
}

output "sg_db_id" {
  description = "ID of the db security group"
  value       = aws_security_group.db.id
}
