locals {
  name_prefix = "${var.project}-${var.environment}"
}

# IAM Role para SSM
resource "aws_iam_role" "ssm" {
  name = "${local.name_prefix}-ec2-${var.service_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${local.name_prefix}-ec2-${var.service_name}-role"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${local.name_prefix}-ec2-${var.service_name}-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_instance" "service" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name != "" ? var.key_name : null  # opcional
  iam_instance_profile   = aws_iam_instance_profile.ssm.name   # <-- isto é o novo

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${local.name_prefix}-ec2-${var.service_name}"
    Service     = var.service_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}