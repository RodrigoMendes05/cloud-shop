locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_instance" "service" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "${local.name_prefix}-ec2-${var.service_name}"
    Service = var.service_name
  }
}