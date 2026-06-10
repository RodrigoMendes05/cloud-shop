output "queue_url" {
  description = "URL da queue SQS principal"
  value       = aws_sqs_queue.orders.url
}

output "queue_arn" {
  description = "ARN da queue SQS principal"
  value       = aws_sqs_queue.orders.arn
}

output "dlq_url" {
  description = "URL da Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN da Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.arn
}
