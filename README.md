# cloud-shop

Sistema de e-commerce baseado em microserviços, deployado em AWS com infraestrutura totalmente automatizada via Terraform e GitHub Actions.

## O que é isto

Cinco serviços Spring Boot comunicam entre si via HTTP síncrono e via AWS SQS para eventos assíncronos. Toda a infraestrutura é provisionada com Terraform, os containers são geridos via Docker, e o deploy é feito automaticamente por SSM sem necessidade de SSH.

```
Internet → api-gateway → user-service
                       → product-service
                       → order-service → SQS → notification-service
```

## Serviços

| Serviço               | Porta | Responsabilidade                        |
|-----------------------|-------|-----------------------------------------|
| api-gateway           | 8080  | Routing, ponto de entrada público       |
| user-service          | 8081  | Gestão de utilizadores, PostgreSQL      |
| product-service       | 8082  | Catálogo de produtos, PostgreSQL        |
| order-service         | 8083  | Encomendas, publica eventos em SQS      |
| notification-service  | 8084  | Consome SQS, regista notificações       |

## Stack

- **Cloud:** AWS (eu-central-1) — EC2, RDS PostgreSQL, SQS, SSM, IAM
- **IaC:** Terraform com módulos (vpc, compute, database, queue)
- **Containers:** Docker, Docker Hub
- **CI/CD:** GitHub Actions com OIDC (sem credenciais hardcoded)
- **Secrets:** AWS SSM Parameter Store

## Deploy rápido

```bash
# 1. Pré-requisitos: AWS CLI, Terraform >= 1.9, Docker

# 2. Clonar e configurar
git clone https://github.com/RodrigoMendes05/cloud-shop
cd cloud-shop

# 3. Provisionar infraestrutura
cd infrastructure/terraform/enviroments/dev
cp terraform.tfvars.example terraform.tfvars
# editar terraform.tfvars com db_password e ami_id
terraform init
terraform apply

# 4. O pipeline de CI/CD trata do build e deploy automaticamente
# Ver .github/workflows/ci.yml
```

Ver [docs/setup.md](docs/setup.md) para instruções detalhadas.

## Documentação

- [Arquitetura](docs/architecture.md)
- [Setup](docs/setup.md)
- [Deploy](docs/deployment.md)
- [Segurança](docs/security.md)
- [Limitações](docs/limitations.md)