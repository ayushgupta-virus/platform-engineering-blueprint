# Cost Optimization

Cost is controlled per-environment through Terraform variables so staging stays
cheap while production is sized for resilience.

## Measures applied

| Measure | How | Where |
| --- | --- | --- |
| **Burstable DB in staging** | `B_Standard_B1ms` vs. `GP_Standard_D2s_v3` in prod | `environments/*.tfvars` |
| **Right-sized nodes** | `Standard_D2s_v3` (staging) vs. `D4s_v3` (prod) | `*.tfvars` |
| **Cluster autoscaling** | Node pools scale to `min_count` at idle | `modules/aks` |
| **Pod autoscaling** | HPA scales replicas on CPU/memory | `k8s/base/hpa.yaml` |
| **Log retention tiers** | 30 days staging / 90 days prod | `log_retention_days` |
| **No geo-redundancy in staging** | Geo backup + HA off in staging | `*.tfvars` |
| **ACR SKU per env** | Standard (staging) / Premium (prod, geo-replication) | `acr_sku` |
| **System/user node split** | `only_critical_addons_enabled` keeps system pool small | `modules/aks` |
| **Scale-to-min off-hours** | Autoscaler + optional `az aks stop` for staging | RUNBOOK |

## Additional levers (documented, not all enabled)

- **Stop staging AKS out of hours**: `az aks stop` / `az aks start` to avoid
  paying for idle nodes overnight.
- **Azure Reservations / Savings Plans** for steady-state prod compute (up to
  ~40–60% vs. pay-as-you-go).
- **Spot node pool** for non-critical/batch workloads.
- **Log Analytics Basic Logs / data collection rules** to cut ingestion cost for
  high-volume, low-value logs.
- **Budgets + cost alerts** (Azure Cost Management) on the resource group.
- **Delete PR/preview environments automatically** after merge.

## Rough monthly cost shape (indicative)

> Illustrative only — actual pricing varies by region and usage.

| Component | Staging | Production |
| --- | --- | --- |
| AKS nodes | 1–3 × D2s_v3 | 2–6 × D4s_v3 |
| PostgreSQL | Burstable B1ms | GP D2s_v3 + HA |
| ACR | Standard | Premium |
| Log Analytics | ~few GB/day, 30d | higher volume, 90d |
| Grafana / Monitor | Managed (per-user / ingestion) | same |

The single biggest staging saving is **autoscaling to minimum + stopping the
cluster off-hours**; the biggest prod saving is **reservations** for the
predictable baseline.
