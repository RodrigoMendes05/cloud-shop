# Policy que permite ao GitHub Actions fazer deploy via SSM
resource "aws_iam_role_policy" "gha_ssm_deploy" {
  name = "shop-dev-ssm-deploy"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy que permite ao GitHub Actions ler outputs do Terraform
# (descrever SQS para verificar que a queue existe)
resource "aws_iam_role_policy" "gha_sqs_read" {
  name = "shop-dev-sqs-read"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:ListQueues"
        ]
        Resource = "*"
      }
    ]
  })
}
