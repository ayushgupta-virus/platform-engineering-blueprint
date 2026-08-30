# Runbook

Operational procedures for the platform.

## CI/CD configuration

Configure these once in the GitHub repository.

### Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Purpose |
| --- | --- |
| `AZURE_CLIENT_ID` | App registration (OIDC) client id |
| `AZURE_TENANT_ID` | Entra tenant id |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `SLACK_WEBHOOK_URL` | Incoming webhook for failure notifications |

### Variables (… → Variables)

| Variable | Example |
| --- | --- |
| `ACR_NAME` / `ACR_LOGIN_SERVER` | `acrplatbluestagingabc123` / `...azurecr.io` |
| `STAGING_RESOURCE_GROUP` / `PROD_RESOURCE_GROUP` | `rg-platblue-staging` |
| `STAGING_AKS_NAME` / `PROD_AKS_NAME` | `aks-platblue-staging` |
| `STAGING_PGHOST` / `PROD_PGHOST` | Terraform `postgres_fqdn` |
| `STAGING_PGUSER` / `PROD_PGUSER` | `pgadmin` |
| `STAGING_WORKLOAD_CLIENT_ID` / `PROD_...` | Terraform `workload_identity_client_id` |
| `STAGING_KEYVAULT_NAME` / `PROD_...` | Terraform `key_vault_name` |
| `TFSTATE_RG` / `TFSTATE_STORAGE` | Bootstrap outputs |

### OIDC federation

Create an Entra app registration and add **federated credentials** for the repo:

```bash
az ad app create --display-name "platform-blueprint-cicd"
# Add federated credentials for:
#   repo:<org>/<repo>:ref:refs/heads/main
#   repo:<org>/<repo>:pull_request
#   repo:<org>/<repo>:environment:staging
#   repo:<org>/<repo>:environment:production
# Grant the app Contributor on the target subscription/resource groups.
```

### Environments

Create `staging` and `production` GitHub Environments. On **production**, add
**required reviewers** — this enforces the manual approval step in `cd.yml`.

## Common operations

### Get cluster access

```bash
az aks get-credentials -g rg-platblue-staging -n aks-platblue-staging
kubectl -n app get pods,svc,hpa
```

### Tail application logs

```bash
kubectl -n app logs -l app=todo-api -f
# or in Log Analytics:
#   ContainerLogV2 | where PodNamespace == "app" | order by TimeGenerated desc
```

### Roll back a deployment

```bash
kubectl -n app rollout undo deployment/todo-api
kubectl -n app rollout status deployment/todo-api
```

### Force a new deploy

Re-run the CD workflow, or:

```bash
kubectl -n app set image deployment/todo-api \
  todo-api=<acr>.azurecr.io/todo-api:<tag>
```

## Database

### Connect (from a temporary pod inside the VNet)

```bash
kubectl -n app run psql --rm -it --image=postgres:16-alpine -- \
  psql "host=<postgres_fqdn> user=pgadmin dbname=appdb sslmode=require"
```

### Point-in-time restore

```bash
az postgres flexible-server restore \
  --resource-group rg-platblue-prod \
  --name psql-platblue-prod-restored \
  --source-server psql-platblue-prod \
  --restore-time "2026-08-29T10:00:00Z"
```

### Manual backup (logical dump)

```bash
pg_dump "host=<fqdn> user=pgadmin dbname=appdb sslmode=require" \
  | gzip > appdb-$(date +%F).sql.gz
```

## Incident checklist

1. Check the **Application (RED)** Grafana dashboard for error/latency spikes.
2. `kubectl -n app get pods` — look for `CrashLoopBackOff` / restarts.
3. `kubectl -n app describe pod <pod>` and `logs` for the failing container.
4. Verify `/ready` — if failing, check PostgreSQL health and NSG/DNS.
5. Check active alerts and the Slack channel for the triggering signal.
6. Roll back the last deploy if a release caused it (see above).

## Teardown

```bash
cd terraform
terraform destroy -var-file=environments/staging.tfvars
# bootstrap state storage is destroyed separately:
cd bootstrap && terraform destroy
```
