output "instance_id" {
  value = aws_instance.service.id
}

output "public_ip" {
  value = aws_instance.service.public_ip
}

output "private_ip" {
  value = aws_instance.service.private_ip
}