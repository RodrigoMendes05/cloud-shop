# Policy que permite ao GitHub Actions fazer deploy via SSM
resource "aws_iam_role_policy" "gha_ssm_deploy" {
  name = "shop-dev-ssm-deploy"
  role = "shop-gha-deployer"   # nome do role que já existe

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