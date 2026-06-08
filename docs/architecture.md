# Arquitetura do Sistema

## Visão Geral

Sistema de e-commerce baseado em microserviços, deployado em AWS (eu-central-1).
O projeto usa a aplicação de laboratório como base (Approach A) e estende-a com
infraestrutura cloud-native: VPC customizada, EC2, RDS PostgreSQL, SQS para
comunicação assíncrona, Terraform para IaC, Ansible para configuração e
GitHub Actions para CI/CD.

## Serviços

| Serviço              | Responsabilidade                          |
|----------------------|-------------------------------------------|
| api-gateway          | Ponto de entrada, routing para serviços   |
| user-service         | Gestão de utilizadores                    |
| product-service      | Catálogo de produtos, stock               |
| order-service        | Criação de encomendas, publica em SQS     |
| notification-service | Consome SQS, regista notificações         |

## Comunicação

- **Síncrona (HTTP):** api-gateway → user/product/order-service
- **Assíncrona (SQS):** order-service → fila `shop-dev-orders` → notification-service

## Infraestrutura AWS

- **Região:** eu-central-1
- **VPC:** CIDR 10.0.0.0/16
- **Subnets públicas:** 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)
- **Subnets privadas:** 10.0.10.0/24 (AZ-a), 10.0.11.0/24 (AZ-b)
- **EC2:** t3.micro por serviço (subnets privadas, exceto api-gateway)
- **RDS:** db.t3.micro PostgreSQL (subnet privada)
- **SQS:** fila standard + DLQ

## IaC & Automação

- Terraform com módulos: vpc, compute, database, queue
- Ansible para configurar Docker em cada EC2
- GitHub Actions: CI em PRs, deploy em merge para main
- OIDC para autenticação AWS sem credenciais hardcoded

## Diagrama (a completar)

<!-- diagrama -->
