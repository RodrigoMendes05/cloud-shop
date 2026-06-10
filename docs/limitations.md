# Limitações e Melhorias Futuras

## Limitações actuais

### Infraestrutura

**EC2s em subnets públicas**
Os serviços internos (user, product, order, notification) estão em subnets públicas com IP público atribuído. O correcto seria subnets privadas com NAT Gateway. Optou-se por subnets públicas porque o NAT Gateway custa ~€30/mês mesmo sem tráfego, o que não é justificável num ambiente de dev/demo. Os security groups compensam parcialmente: o sg-app só aceita tráfego do sg-web, não da internet directamente.

**Single AZ**
Toda a infraestrutura está numa única availability zone. Sem failover automático em caso de falha de AZ.

**Sem ALB**
O api-gateway está directamente exposto numa EC2 sem load balancer à frente. Sem health checks automáticos nem failover.

### Base de dados

**Sem backups**
`backup_retention_period = 0` no RDS — adequado para dev, inaceitável em produção.

**Single AZ RDS**
Sem Multi-AZ deployment. Uma falha de hardware no host RDS causa downtime.

**Password em `terraform.tfvars`**
A password do RDS existe localmente no `terraform.tfvars` (fora do Git). Idealmente seria lida 100% do SSM também no apply local, mas o Terraform não suporta data sources no backend config.

### Aplicação

**Sem health endpoints**
Os serviços não expõem `/health` ou `/actuator/health`. O pipeline não verifica se o serviço arrancou correctamente após o deploy — só verifica se o comando SSM terminou com sucesso.

**Deploy não é zero-downtime**
O processo é `docker stop` → `docker rm` → `docker run`. Há um período de indisponibilidade entre o stop e o run do novo container.

**Sem circuit breaker**
As chamadas Feign entre serviços não têm circuit breaker (Resilience4j). Uma falha no user-service bloqueia o order-service.

### CI/CD

**Sem environment gates**
Não há aprovação manual antes do deploy para produção — o merge para main dispara o deploy directamente. Aceitável em dev, deve ter gate em prod.

**Sem rollback automático**
Se o deploy falhar a meio, não há rollback. Seria necessário re-correr o pipeline com a tag anterior.

## Melhorias futuras (por prioridade)

1. **Subnets privadas para serviços internos** — mover user/product/order/notification para subnets privadas com NAT Gateway quando o custo for aceitável
2. **ALB + health checks** — substituir exposição directa da EC2 por ALB com target groups e health check no `/actuator/health`
3. **Multi-AZ RDS** — activar para qualquer ambiente que não seja exclusivamente dev/demo
4. **Zero-downtime deploy** — blue/green deployment ou rolling update com dois containers em simultâneo
5. **Observabilidade** — CloudWatch Logs com `awslogs` driver, métricas de queue depth, alarmes SNS
6. **Secrets Manager** em vez de SSM Parameter Store — suporta rotação automática de passwords
7. **ECS/Fargate** — eliminar gestão de EC2s; o deploy seria uma actualização de task definition