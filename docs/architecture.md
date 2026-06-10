# Arquitetura do Sistema

## Visão Geral

Sistema de e-commerce baseado em microserviços deployado em AWS (eu-central-1).
Usa a aplicação de laboratório como base (Approach A) e estende-a com infraestrutura
cloud-native: VPC customizada, EC2, RDS PostgreSQL, SQS para comunicação assíncrona,
Terraform para IaC e GitHub Actions para CI/CD.

## Diagrama de Arquitectura

```mermaid
flowchart TD
    Internet([Internet]) -->|HTTP :8080| GW

    subgraph VPC["VPC 10.0.0.0/16"]
        subgraph Public["Subnets Públicas (10.0.1.0/24, 10.0.2.0/24)"]
            GW["api-gateway\nEC2 t3.micro :8080"]
        end

        subgraph App["Subnets Públicas — App tier (sg-app)"]
            US["user-service\nEC2 t3.micro :8081"]
            PS["product-service\nEC2 t3.micro :8082"]
            OS["order-service\nEC2 t3.micro :8083"]
            NS["notification-service\nEC2 t3.micro :8084"]
        end

        subgraph Private["Subnets Privadas (10.0.10.0/24, 10.0.11.0/24)"]
            RDS[("RDS PostgreSQL\ndb.t3.micro\nshopdb")]
        end
    end

    SQS["AWS SQS\nshop-dev-orders\n+ DLQ"]
    SSM["AWS SSM\nParameter Store\n/shop/dev/rds/password"]

    GW -->|HTTP| US
    GW -->|HTTP| PS
    GW -->|HTTP| OS
    OS -->|OpenFeign| US
    OS -->|OpenFeign| PS
    OS -->|publish| SQS
    SQS -->|consume| NS

    US --> RDS
    PS --> RDS
    OS --> RDS

    OS -.->|read secret| SSM
    US -.->|read secret| SSM
    PS -.->|read secret| SSM
```

## Fluxo de Criação de Encomenda

```mermaid
sequenceDiagram
    participant C as Cliente
    participant GW as api-gateway
    participant OS as order-service
    participant US as user-service
    participant PS as product-service
    participant DB as RDS PostgreSQL
    participant SQ as SQS
    participant NS as notification-service

    C->>GW: POST /orders
    GW->>OS: POST /orders (StripPrefix)
    OS->>US: GET /users/{id} (Feign)
    US-->>OS: UserDTO
    OS->>PS: GET /products/{id} (Feign)
    PS-->>OS: ProductDTO
    OS->>DB: INSERT order
    OS->>SQ: publish OrderCreatedEvent
    OS-->>GW: 201 Created
    GW-->>C: 201 Created
    SQ-->>NS: poll (5s interval)
    NS->>NS: log [NOTIFICATION] New order...
    NS->>SQ: deleteMessage (ack)
```

## Serviços

| Serviço              | Porta | Responsabilidade                          | Base de dados |
|----------------------|-------|-------------------------------------------|---------------|
| api-gateway          | 8080  | Routing, ponto de entrada público         | —             |
| user-service         | 8081  | Gestão de utilizadores                    | PostgreSQL     |
| product-service      | 8082  | Catálogo de produtos, stock               | PostgreSQL     |
| order-service        | 8083  | Criação de encomendas, publica em SQS     | PostgreSQL     |
| notification-service | 8084  | Consome SQS, regista notificações         | —             |

## Comunicação

- **Síncrona (HTTP/Feign):** api-gateway → user/product/order-service; order-service → user/product-service
- **Assíncrona (SQS):** order-service publica `OrderCreatedEvent` → fila `shop-dev-orders` → notification-service consome com `@Scheduled(fixedDelay=5000)`
- **Retry/DLQ:** mensagens que falham 3 vezes são movidas para `shop-dev-orders-dlq`

## Infraestrutura AWS

| Recurso         | Configuração                                          |
|-----------------|-------------------------------------------------------|
| VPC             | CIDR 10.0.0.0/16, DNS hostnames activos               |
| Subnets públicas| 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)              |
| Subnets privadas| 10.0.10.0/24 (AZ-a), 10.0.11.0/24 (AZ-b)            |
| EC2             | t3.micro por serviço, Amazon Linux 2023               |
| RDS             | db.t3.micro, PostgreSQL 16, subnet privada            |
| SQS             | Standard queue + DLQ, maxReceiveCount=3               |
| SSM             | Parameter Store para secrets, AmazonSSMManagedInstanceCore nos EC2s |

## Módulos Terraform

```
modules/
├── vpc/        VPC, subnets, IGW, route tables, security groups
├── compute/    EC2 + IAM role SSM + instance profile
├── database/   RDS PostgreSQL + subnet group
└── queue/      SQS + DLQ + resource policy
```