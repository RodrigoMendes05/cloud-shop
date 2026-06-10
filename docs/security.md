# Segurança

## Modelo IAM

### GitHub Actions — `shop-gha-deployer`

Role assumida pelo pipeline via OIDC (sem credenciais estáticas). Tem cinco políticas inline com âmbito mínimo:

| Política              | Acções permitidas                                              | Âmbito                                      |
|-----------------------|----------------------------------------------------------------|---------------------------------------------|
| `gha_ssm_deploy`      | `ssm:SendCommand`, `GetCommandInvocation`, `DescribeInstanceInformation` | Instâncias com tag `Project=shop`      |
| `gha_ec2_describe`    | `ec2:DescribeInstances`, `DescribeInstanceStatus`              | `*` (API list-only, não suporta ARN)        |
| `gha_sqs_read`        | `sqs:GetQueueUrl`, `GetQueueAttributes`                        | `arn:aws:sqs:...:shop-dev-orders`           |
| `gha_tf_state`        | S3 get/put/delete + DynamoDB lock                              | Bucket e tabela específicos                 |
| `gha_tf_provision`    | VPC, EC2, RDS, SQS, IAM roles do projecto, SSM params          | Prefixo `shop-dev-*`                        |

**Trust policy** — restrita ao repositório específico:
```json
{
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:RodrigoMendes05/cloud-shop:*"
    }
  }
}
```

### EC2 Instance Roles — `shop-dev-ec2-<serviço>-role`

Cada EC2 tem o seu próprio role com:

- `AmazonSSMManagedInstanceCore` (policy gerida AWS) — permite acesso SSM sem SSH
- `shop-dev-ec2-app-policy` (policy gerida do projecto) — permite:
  - `sqs:ReceiveMessage`, `DeleteMessage`, `SendMessage` nas filas `shop-dev-orders` e `shop-dev-orders-dlq`
  - `ssm:GetParameter` no namespace `/shop/*`
  - `kms:Decrypt` na chave `alias/aws/ssm` para desencriptar SecureStrings

## Gestão de Secrets

### O que está onde

| Secret              | Onde está guardado              | Como é acedido                              |
|---------------------|---------------------------------|---------------------------------------------|
| RDS password        | SSM Parameter Store (SecureString, `/shop/dev/rds/password`) | EC2 lê em runtime via `aws ssm get-parameter` |
| Docker Hub token    | GitHub Actions Secret           | Só usado no job de build, nunca chega às EC2s |
| RDS endpoint (host) | GitHub Actions Secret           | Não é um secret em si — host público do RDS |
| AWS Role ARN        | GitHub Actions Secret           | Usado no OIDC assume-role                   |

### O que nunca acontece

- A password do RDS **nunca** aparece nos logs do GitHub Actions (`::add-mask::` aplicado)
- A password do RDS **nunca** viaja como variável de ambiente pelo pipeline — é lida localmente pela EC2 no momento do deploy
- Sem credenciais AWS estáticas em lado nenhum — autenticação via OIDC
- `terraform.tfvars` está no `.gitignore` — nunca entra no repositório

## Networking

### Security Groups

```
Internet
    │ :80, :8080
    ▼
sg-web (api-gateway)
    │ :8081-8084
    ▼
sg-app (user, product, order, notification)
    │ :5432
    ▼
sg-db (RDS PostgreSQL)
```

- **sg-web:** aceita HTTP (:80, :8080) da internet; sem porta 22 (SSH removido no Day 9)
- **sg-app:** aceita tráfego (:8081-8084) apenas do sg-web e de si próprio (inter-service); sem porta 22
- **sg-db:** aceita PostgreSQL (:5432) apenas do sg-app via SG reference — nunca de CIDRs

### RDS

- `publicly_accessible = false` — sem IP público, não acessível fora da VPC
- Colocado em subnets privadas sem rota para o IGW
- Acesso controlado exclusivamente pelo sg-db

### EC2s

- Sem key pair configurado — acesso exclusivamente via AWS SSM Session Manager
- Porta 22 fechada nos security groups

## Scan de Credenciais

O pipeline corre `gitleaks` em cada PR com fetch do histórico completo (`fetch-depth: 0`). O job falha se encontrar qualquer padrão de credencial. Configurado em `.github/workflows/ci.yml` no job `secret-scan`.

## Limitações Conhecidas

- EC2s estão em subnets públicas (têm IP público) — idealmente os serviços internos estariam em subnets privadas com NAT Gateway, mas o custo (~€30/mês) não justifica para um ambiente de dev
- Sem WAF nem ALB — o api-gateway está directamente exposto
- Sem rotação automática de secrets no SSM Parameter Store (disponível no Secrets Manager)
- `backup_retention_period = 0` no RDS — sem backups automáticos no ambiente dev
