# Architecture

## Overview

A containerized Node.js API (`todo-api`) runs on **Azure Kubernetes Service
(AKS)** inside a private subnet. It is fronted by an Azure **Standard Load
Balancer** and backed by **Azure Database for PostgreSQL — Flexible Server**
deployed with private VNet integration. Images live in **Azure Container
Registry (ACR)**; secrets live in **Azure Key Vault**; observability is provided
by **Azure Monitor** (Container Insights + managed Prometheus), **Log
Analytics** and **Managed Grafana**.

## AWS → Azure service mapping

For teams coming from AWS, here are the equivalent Azure services used:

| AWS | This implementation (Azure) |
| --- | --- |
| VPC + public/private subnets | Virtual Network + `snet-public` / `snet-aks` / `snet-db` |
| EC2 / ECS / **EKS** | **AKS** (Azure Kubernetes Service) |
| RDS for PostgreSQL | Azure Database for PostgreSQL Flexible Server |
| Security groups | Network Security Groups (NSGs) |
| Load balancer (ELB/ALB) | Azure Standard Load Balancer (via K8s `Service` type LoadBalancer) |
| ECR | Azure Container Registry (ACR) |
| Secrets Manager / Parameter Store | Azure Key Vault (+ CSI driver) |
| CloudWatch | Azure Monitor + Log Analytics |
| Managed Prometheus / Grafana | Azure Monitor managed Prometheus + Managed Grafana |
| S3 (Terraform state) + DynamoDB lock | Azure Storage (blob) backend with lease-based locking |

## Network topology

- **VNet** `10.20.0.0/16`.
- **`snet-public`** `10.20.1.0/24` — ingress tier; NSG allows inbound 80/443 from
  the internet. Hosts the public load balancer / future Application Gateway.
- **`snet-aks`** `10.20.16.0/20` — private AKS node pools; NSG allows only
  intra-VNet + Azure LB traffic and denies inbound internet.
- **`snet-db`** `10.20.32.0/24` — delegated to
  `Microsoft.DBforPostgreSQL/flexibleServers`; NSG allows 5432 only from the AKS
  subnet. PostgreSQL has **no public endpoint**; DNS resolves via a private DNS
  zone linked to the VNet.

Azure subnets are not intrinsically "public/private" (unlike AWS). The tiers are
enforced with NSG rules, private endpoints and the absence of public IPs.

## Compute (AKS)

- **System node pool** (`only_critical_addons_enabled`) isolates platform
  add-ons from application workloads.
- **User node pool** (`app`) runs the application, labelled `workload=application`.
- Both pools autoscale; the workload also scales via a **HorizontalPodAutoscaler**
  (CPU + memory) with a **PodDisruptionBudget** for safe rollouts.
- **Azure CNI** networking + **Calico** network policy.
- **OIDC issuer + workload identity** enabled so pods authenticate to Azure AD
  (used by the Key Vault CSI driver) without static credentials.

## Data

- PostgreSQL Flexible Server, private access, TLS enforced
  (`require_secure_transport=ON`).
- Schema is applied by an **init container** (`node src/migrate.js`) before the
  app container starts, keeping migrations in the deploy path.
- Backups: automated daily + point-in-time restore; geo-redundant + zone-
  redundant HA enabled for production (see `environments/prod.tfvars`).

## Key architecture decisions

1. **AKS over VMs / Container Apps.** AKS provides a managed-Kubernetes model
   with the most platform-engineering depth (node pools, HPA, PDB, CSI, workload
   identity, managed Prometheus). Container Apps would be simpler but hides much
   of that control.
2. **Kustomize base + overlays** instead of Helm — fewer moving parts for a
   two-environment demo while still keeping environment drift explicit.
3. **Terraform modules** (`network`, `aks`, `database`, `acr`, `keyvault`,
   `monitoring`) for reuse and clear ownership boundaries.
4. **Metric alerts live in the root module**, not `monitoring`, to avoid a
   module dependency cycle (the monitoring module produces the Log Analytics /
   Prometheus workspaces that the AKS module consumes; the alerts in turn depend
   on the AKS/DB resource IDs).
5. **OIDC for CI/CD auth** — no long-lived cloud credentials in GitHub.
6. **Managed Prometheus + Managed Grafana** over self-hosted to reduce
   operational burden while still using the standard PromQL/Grafana workflow.

## Environments

| | Staging | Production |
| --- | --- | --- |
| DB SKU | `B_Standard_B1ms` (burstable) | `GP_Standard_D2s_v3` |
| DB HA / geo-backup | off / off | zone-redundant / geo-redundant |
| Node VM size | `Standard_D2s_v3` | `Standard_D4s_v3` |
| App replicas (min–max) | 2–10 | 4–20 |
| Log retention | 30 days | 90 days |
| ACR SKU | Standard | Premium (geo-replication capable) |
| Key Vault purge protection | off | on |
