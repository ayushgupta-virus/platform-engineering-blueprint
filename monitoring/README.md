# Monitoring & Logging

This directory contains the observability assets for the platform. The stack is
built on **Azure Monitor** and is provisioned by Terraform (see
[`terraform/modules/monitoring`](../terraform/modules/monitoring)).

## Components

| Concern | Service | Provisioned by |
| --- | --- | --- |
| Infra metrics (CPU/memory/disk) | Container Insights → Log Analytics | `modules/aks` (`oms_agent`) |
| App metrics (rate/errors/latency) | Managed Prometheus (Azure Monitor workspace) | `modules/aks` (`monitor_metrics` + DCR) |
| Database metrics | Azure Monitor platform metrics | Azure (built-in) + alerts in `main.tf` |
| Centralized logs | Log Analytics Workspace | `modules/monitoring` |
| Dashboards | Azure Managed Grafana | `modules/monitoring` |
| Alerting / notifications | Action group (email + Slack) + metric/Prometheus alerts | `modules/monitoring`, `main.tf` |

## Dashboards (2)

- [`dashboards/infrastructure-dashboard.json`](dashboards/infrastructure-dashboard.json)
  — node CPU / memory / disk, running pods, restarts, CPU throttling.
- [`dashboards/application-dashboard.json`](dashboards/application-dashboard.json)
  — request rate, error rate, latency (p50/p95/p99), status codes, process memory.

### Import into Managed Grafana

```bash
# Grafana endpoint comes from `terraform output grafana_endpoint`.
# In the Grafana UI: Dashboards → New → Import → upload the JSON,
# then select the "Managed Prometheus" data source when prompted.
```

The Azure Monitor workspace is auto-linked to Managed Grafana by Terraform
(`azure_monitor_workspace_integrations`), so the Prometheus data source is
available out of the box.

## Application metrics

The app exposes Prometheus metrics at `/metrics`:

- `http_requests_total{method,route,status_code}` — request & error rate.
- `http_request_duration_seconds_bucket{...}` — latency histogram.
- `app_*` — default Node.js process metrics (memory, event loop, GC).

A `PodMonitor` ([`k8s/base/podmonitor.yaml`](../k8s/base/podmonitor.yaml)) tells
managed Prometheus to scrape these pods.

## Centralized logging

All three log categories land in the Log Analytics workspace:

- **Application logs** — structured JSON from the app (`pino`) to stdout,
  collected by Container Insights into `ContainerLogV2`.
- **System logs** — node/kubelet/syslog collected by Container Insights
  (`KubeEvents`, `Syslog`).
- **Access logs** — HTTP request logs (`pino-http`) in `ContainerLogV2`;
  cloud-level access via `AzureDiagnostics` / Load Balancer diagnostics.

### Sample KQL queries

```kusto
// Application error logs in the last hour
ContainerLogV2
| where PodNamespace == "app"
| where LogMessage has "\"level\":\"error\""
| order by TimeGenerated desc

// HTTP access log latency (from pino-http responseTime field)
ContainerLogV2
| where PodNamespace == "app"
| extend d = parse_json(LogMessage)
| where isnotempty(d.responseTime)
| summarize p95 = percentile(todouble(d.responseTime), 95) by bin(TimeGenerated, 5m)

// Node system events
KubeEvents
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
```

## Alerts

- Metric alerts (Terraform): AKS node CPU > 80%, PostgreSQL storage > 80%.
- Prometheus alerts ([`prometheus/alert-rules.yaml`](prometheus/alert-rules.yaml)):
  high error rate, high p95 latency, no traffic, no ready pods.
- All alerts fire through the action group → email + Slack webhook.
