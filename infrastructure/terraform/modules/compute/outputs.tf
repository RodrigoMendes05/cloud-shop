output "instance_id" {
  value = aws_instance.service.id
}

output "public_ip" {
  value = aws_instance.service.public_ip
}

output "private_ip" {
  value = aws_instance.service.private_ip
}

output "instance_role_arn" {
  description = "ARN da IAM role associada ao EC2 (usado para queue policy)"
  value       = aws_iam_role.ssm.arn
}
