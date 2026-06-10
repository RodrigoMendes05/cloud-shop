# ─────────────────────────────────────────────────────────────────────────────
# SSM Parameter Store — Day 8
# Guarda a password do RDS como SecureString encriptada com a chave aws/ssm.
# O valor é passado via terraform.tfvars (que está no .gitignore).
# As EC2s lêem-no em runtime — a password nunca viaja pelo pipeline.
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_ssm_parameter" "rds_password" {
  name        = "/shop/dev/rds/password"
  description = "RDS shopdb password para o ambiente dev"
  type        = "SecureString"
  value       = var.db_password

  # Usa a chave gerida pela AWS para SSM (sem custo extra)
  # Para maior controlo, substituir por uma aws_kms_key dedicada
  key_id = "alias/aws/ssm"

  tags = {
    Project     = "shop"
    Environment = "dev"
    ManagedBy   = "terraform"
    Secret      = "true"
  }

  # Evita que o Terraform actualize o parâmetro se a password já existir
  # e for igual — útil para não forçar um apply desnecessário
  lifecycle {
    ignore_changes = [value]
  }
}

# Output do nome do parâmetro (não do valor!) para referência noutros módulos
output "ssm_rds_password_name" {
  description = "Nome do parâmetro SSM que guarda a password RDS"
  value       = aws_ssm_parameter.rds_password.name
}
