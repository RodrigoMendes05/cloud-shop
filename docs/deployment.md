# Deployment

## Pipeline automático (uso normal)

O deploy acontece automaticamente. Basta fazer push para `main`:

```
push main
    │
    ├── lint (terraform fmt + tflint)
    ├── secret-scan (gitleaks)
    │
    ├── terraform-apply
    │     └── lê db_password do SSM Parameter Store
    │         terraform apply -auto-approve
    │
    ├── build-and-push (matrix: 5 serviços em paralelo)
    │     └── docker build + push para Docker Hub
    │         tag: <username>/shop-<serviço>:<git-sha>
    │
    └── deploy (matrix: 5 serviços em paralelo)
          └── SSM send-command para cada EC2
              ├── docker pull
              ├── docker stop/rm (container anterior)
              └── docker run (novo container)
```

## Pull Request

Ao abrir um PR para `main`, o pipeline corre automaticamente:

1. `lint` — verifica `terraform fmt` e `tflint`
2. `secret-scan` — gitleaks no histórico completo
3. `terraform-plan` — comenta o output do plan directamente no PR

O merge só é permitido se todos os checks passarem (branch protection).

## Deploy manual (emergência)

Se precisares de fazer deploy sem passar pelo pipeline:

```bash
# 1. Build e push local
docker build -t <username>/shop-order-service:manual ./services/order-service
docker push <username>/shop-order-service:manual

# 2. Obter instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Service,Values=order" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text --region eu-central-1

# 3. Enviar comando via SSM
aws ssm send-command \
  --instance-ids "i-XXXXXXXX" \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["docker pull <username>/shop-order-service:manual","docker stop order-service || true","docker rm order-service || true","docker run -d --name order-service -p 8083:8083 <username>/shop-order-service:manual"]}' \
  --region eu-central-1
```

## Verificar estado após deploy

```bash
# Ver logs de um serviço via SSM
aws ssm start-session --target i-XXXXXXXX --region eu-central-1
# dentro da sessão:
docker logs order-service --tail 50

# Testar o gateway
curl http://<EC2_GATEWAY_PUBLIC_IP>:8080/users
curl http://<EC2_GATEWAY_PUBLIC_IP>:8080/products
curl -X POST http://<EC2_GATEWAY_PUBLIC_IP>:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productId":1,"quantity":2}'
```

## Tear down

```bash
cd infrastructure/terraform/enviroments/dev
terraform destroy -var="db_password=A_TUA_PASSWORD"
```

Verificar no AWS Console que não ficaram recursos órfãos (especialmente RDS e EC2).