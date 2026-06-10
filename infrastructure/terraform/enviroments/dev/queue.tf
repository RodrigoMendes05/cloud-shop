# Recolhe os ARNs das roles dos EC2s (criadas pelo módulo compute)
# para autorizar acesso à queue via resource policy
locals {
  app_role_arns = [
    module.ec2_order.instance_role_arn,
    module.ec2_notification.instance_role_arn,
  ]
}

module "queue" {
  source = "../../modules/queue"

  project     = var.project
  environment = var.environment

  allowed_role_arns = concat(
    local.app_role_arns,
    ["arn:aws:iam::311601425081:role/shop-gha-deployer"] # GHA pode inspecionar a queue
  )
}
