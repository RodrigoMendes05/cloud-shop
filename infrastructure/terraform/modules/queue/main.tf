locals {
  name_prefix = "${var.project}-${var.environment}"
}

# Dead-Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                       = "${local.name_prefix}-orders-dlq"
  message_retention_seconds  = 1209600 # 14 dias
  receive_wait_time_seconds  = 20      # long polling

  tags = {
    Name    = "${local.name_prefix}-orders-dlq"
    Service = "messaging"
  }
}

# Main queue com redrive para DLQ após 3 tentativas
resource "aws_sqs_queue" "orders" {
  name                       = "${local.name_prefix}-orders"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 dia
  receive_wait_time_seconds  = 20    # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name    = "${local.name_prefix}-orders"
    Service = "messaging"
  }
}

# Política de acesso à queue principal — permite que EC2s com a IAM role
# da aplicação façam send/receive/delete
resource "aws_sqs_queue_policy" "orders" {
  queue_url = aws_sqs_queue.orders.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAppRoles"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_role_arns
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.orders.arn
      }
    ]
  })
}
