# ─────────────────────────────────────────────────────────────────────────────
# IAM — shop-gha-deployer policies (Day 8: least-privilege)
# Cada bloco cobre exatamente o que o pipeline precisa, sem wildcards.
# ─────────────────────────────────────────────────────────────────────────────

# 1. SSM: enviar comandos e verificar estado (deploy via SSM send-command)
resource "aws_iam_role_policy" "gha_ssm_deploy" {
  name = "shop-dev-ssm-deploy"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSendAndInspect"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation"
        ]
        # Restringir ao documento standard e às instâncias com tag Project=shop
        Resource = [
          "arn:aws:ssm:eu-central-1::document/AWS-RunShellScript",
          "arn:aws:ec2:eu-central-1:311601425081:instance/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Project" = "shop"
          }
        }
      },
      {
        # GetCommandInvocation precisa de * no resource (não aceita ARN de instância)
        Sid      = "SSMGetInvocation"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation"]
        Resource = "*"
      }
    ]
  })
}

# 2. EC2: descrever instâncias para resolver IPs e instance IDs no pipeline
resource "aws_iam_role_policy" "gha_ec2_describe" {
  name = "shop-dev-ec2-describe"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*" # DescribeInstances não suporta ARN — é list-only
      }
    ]
  })
}

# 3. SQS: verificar que a queue existe (resolve URL no pipeline)
resource "aws_iam_role_policy" "gha_sqs_read" {
  name = "shop-dev-sqs-read"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSInspect"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:eu-central-1:311601425081:shop-dev-orders"
      }
    ]
  })
}

# 4. Terraform state: S3 + DynamoDB locking (terraform init/plan/apply)
resource "aws_iam_role_policy" "gha_tf_state" {
  name = "shop-dev-tf-state"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3State"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::shop-tf-state-eu-central-1",
          "arn:aws:s3:::shop-tf-state-eu-central-1/*"
        ]
      },
      {
        Sid    = "DynamoLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:eu-central-1:311601425081:table/shop-tf-locks"
      }
    ]
  })
}

# 5. Terraform provisioning: permissões para criar/gerir os recursos do projeto
#    Só os serviços usados: VPC, EC2, RDS, SQS, IAM (para os instance roles), SSM params
resource "aws_iam_role_policy" "gha_tf_provision" {
  name = "shop-dev-tf-provision"
  role = "shop-gha-deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCFull"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
          "ec2:DescribeVpcs", "ec2:DescribeVpcAttribute",
          "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:DescribeSubnets",
          "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
          "ec2:DescribeInternetGateways",
          "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
          "ec2:CreateRoute", "ec2:DeleteRoute",
          "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
          "ec2:DescribeRouteTables",
          "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules",
          "ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones", "ec2:DescribeAccountAttributes"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Instances"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances", "ec2:TerminateInstances",
          "ec2:StartInstances", "ec2:StopInstances",
          "ec2:DescribeInstances", "ec2:DescribeInstanceStatus",
          "ec2:DescribeImages", "ec2:DescribeKeyPairs",
          "ec2:ModifyInstanceAttribute",
          "ec2:AssociateIamInstanceProfile", "ec2:DisassociateIamInstanceProfile",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:DescribeVolumes", "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDS"
        Effect = "Allow"
        Action = [
          "rds:CreateDBInstance", "rds:DeleteDBInstance", "rds:ModifyDBInstance",
          "rds:DescribeDBInstances", "rds:DescribeDBSubnetGroups",
          "rds:CreateDBSubnetGroup", "rds:DeleteDBSubnetGroup",
          "rds:AddTagsToResource", "rds:ListTagsForResource",
          "rds:DescribeDBParameterGroups", "rds:CreateDBParameterGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "SQSManage"
        Effect = "Allow"
        Action = [
          "sqs:CreateQueue", "sqs:DeleteQueue",
          "sqs:SetQueueAttributes", "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl", "sqs:ListQueues",
          "sqs:AddPermission", "sqs:RemovePermission",
          "sqs:TagQueue"
        ]
        Resource = "arn:aws:sqs:eu-central-1:311601425081:shop-dev-*"
      },
      {
        Sid    = "IAMInstanceRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile", "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:PassRole",
          "iam:TagRole", "iam:UntagRole"
        ]
        # Restringir ao prefixo do projeto
        Resource = [
          "arn:aws:iam::311601425081:role/shop-dev-*",
          "arn:aws:iam::311601425081:instance-profile/shop-dev-*"
        ]
      },
      {
        Sid    = "SSMParams"
        Effect = "Allow"
        Action = [
          "ssm:PutParameter", "ssm:GetParameter", "ssm:GetParameters",
          "ssm:DeleteParameter", "ssm:DescribeParameters",
          "ssm:AddTagsToResource"
        ]
        Resource = "arn:aws:ssm:eu-central-1:311601425081:parameter/shop/*"
      },
      {
        Sid    = "KMSForSSMSecureString"
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"
        ]
        # Permite usar a chave padrão aws/ssm gerida pela AWS
        Resource = "arn:aws:kms:eu-central-1:311601425081:alias/aws/ssm"
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM inline policy para os EC2 instance roles (Day 8: acesso a SQS + SSM)
# Adicionada via módulo compute — aqui criamos uma policy gerida e referenciamos
# o ARN no módulo. Alternativa: adicionar aws_iam_role_policy_attachment em cada
# módulo. A solução abaixo é mais DRY: uma policy, cinco attachments.
# ─────────────────────────────────────────────────────────────────────────────

# Policy gerida para os EC2s acederem a SQS e SSM Parameter Store
resource "aws_iam_policy" "ec2_app_policy" {
  name        = "shop-dev-ec2-app-policy"
  description = "Permite aos EC2s do shop ler SQS e SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:SendMessage",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          "arn:aws:sqs:eu-central-1:311601425081:shop-dev-orders",
          "arn:aws:sqs:eu-central-1:311601425081:shop-dev-orders-dlq"
        ]
      },
      {
        Sid    = "SSMParamRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        # Só os parâmetros do projecto shop
        Resource = "arn:aws:ssm:eu-central-1:311601425081:parameter/shop/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = "arn:aws:kms:eu-central-1:311601425081:alias/aws/ssm"
      }
    ]
  })

  tags = {
    Project     = "shop"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Attachments da policy aos 5 instance roles (criados pelo módulo compute)
resource "aws_iam_role_policy_attachment" "ec2_gateway_app" {
  role       = "shop-dev-ec2-gateway-role"
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_user_app" {
  role       = "shop-dev-ec2-user-role"
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_product_app" {
  role       = "shop-dev-ec2-product-role"
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_order_app" {
  role       = "shop-dev-ec2-order-role"
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_notification_app" {
  role       = "shop-dev-ec2-notification-role"
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}
