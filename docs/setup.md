# Setup

## Pré-requisitos

### Ferramentas locais

| Ferramenta     | Versão mínima | Verificar                  |
|----------------|---------------|----------------------------|
| AWS CLI        | v2            | `aws --version`            |
| Terraform      | 1.9           | `terraform -version`       |
| Docker         | 24+           | `docker version`           |
| Git            | qualquer      | `git --version`            |

### AWS

- Conta AWS com permissões de administrador (para o setup inicial)
- AWS CLI configurado: `aws configure` ou `aws sso login`
- Região: `eu-central-1`

### GitHub

- Repositório fork/clone de `RodrigoMendes05/cloud-shop`
- Secrets configurados no repositório (Settings → Secrets → Actions):

| Secret               | Descrição                                              |
|----------------------|--------------------------------------------------------|
| `AWS_ROLE_TO_ASSUME` | ARN do role OIDC: `arn:aws:iam::311601425081:role/shop-gha-deployer` |
| `AWS_REGION`         | `eu-central-1`                                         |
| `DOCKERHUB_USERNAME` | Username Docker Hub                                    |
| `DOCKERHUB_TOKEN`    | Access token Docker Hub                                |
| `RDS_ENDPOINT`       | Endpoint RDS (sem porta): `shop-dev-postgres.c1s6g2uwoh1h.eu-central-1.rds.amazonaws.com:5432` |

## Setup inicial (só uma vez)

### 1. Remote state

```bash
# Criar bucket S3 para Terraform state
aws s3api create-bucket \
  --bucket shop-tf-state-eu-central-1 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws s3api put-bucket-versioning \
  --bucket shop-tf-state-eu-central-1 \
  --versioning-configuration Status=Enabled

# Criar tabela DynamoDB para locking
aws dynamodb create-table \
  --table-name shop-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### 2. OIDC para GitHub Actions

```bash
# Criar OIDC provider (só uma vez por conta AWS)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

O role `shop-gha-deployer` é criado e gerido manualmente ou via Terraform fora do state do projecto.

### 3. SSM Parameter Store — password do RDS

Criar o parâmetro antes do primeiro `terraform apply`:

```bash
aws ssm put-parameter \
  --name "/shop/dev/rds/password" \
  --value "A_TUA_PASSWORD" \
  --type SecureString \
  --region eu-central-1
```

### 4. terraform.tfvars

```bash
cd infrastructure/terraform/enviroments/dev
cp terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars`:
```hcl
db_password = "A_TUA_PASSWORD"   # igual ao que puseste no SSM
ami_id      = "ami-0c8ab82f51d47e1be"  # Amazon Linux 2023 eu-central-1
```

### 5. Primeiro apply

```bash
terraform init
terraform plan
terraform apply
```

A partir daqui o pipeline CI/CD trata de tudo automaticamente em cada push para `main`.