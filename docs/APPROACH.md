# Approach

This document explains the design approach for the platform and the rationale
behind the key decisions.

## Guiding principles

- **Focus on the platform.** The application is a deliberately small todo API —
  the emphasis is on the *platform* around it, not business logic.
- **End-to-end ownership.** Every part (infra → build → deploy → observe →
  operate → document) is wired together so the system actually runs, not just a
  collection of snippets.
- **Production-shaped, demo-sized.** Real patterns (private networking, workload
  identity, autoscaling, PITR backups) sized down to keep costs sane.

## Execution order

1. **Sample application.** A Node.js/Express todo API with `/health`, `/ready`,
   `/metrics`, structured logging, DB access and unit + integration tests. This
   defines the contract everything else deploys and observes.
2. **Containerization.** Multi-stage, non-root Dockerfile with a healthcheck;
   `docker-compose` for a local app + Postgres stack that mirrors prod topology.
3. **Infrastructure (Terraform).** Modular Azure design (network, AKS, database,
   ACR, Key Vault, monitoring) with per-environment `tfvars`, remote state in
   Azure Storage, and outputs feeding the deploy step.
4. **Kubernetes manifests.** Kustomize base + staging/prod overlays: deployment
   (init-container migrations), LoadBalancer service, HPA, PDB, ConfigMap,
   Key Vault CSI secret, PodMonitor.
5. **CI/CD (GitHub Actions).** PR quality gates, image build/scan/push, staging
   deploy, and a manually-approved production deploy.
6. **Monitoring & logging.** Container Insights, managed Prometheus, two Grafana
   dashboards, alerts to email/Slack, centralized logs with KQL examples.
7. **Documentation.** This set of docs plus per-directory READMEs.

## Why these choices

- **Azure + AKS.** Azure was chosen for the target cloud, with AKS as the
  compute platform because it maps cleanly to a managed-Kubernetes model and
  exercises the most relevant platform capabilities. See
  [ARCHITECTURE.md](ARCHITECTURE.md) for the full rationale.
- **Terraform modules + remote state.** Reusable, reviewable, and safe for team
  use (state locking, versioned blobs).
- **OIDC everywhere.** CI authenticates to Azure without stored secrets; pods
  authenticate to Key Vault via workload identity.
- **Kustomize over Helm.** Lower ceremony for two environments while keeping the
  differences between them explicit and diff-able.
- **Managed observability.** Managed Prometheus/Grafana keep the standard tooling
  without running the control plane ourselves.

## Future enhancements

- **Application Gateway + WAF / NGINX ingress** with TLS termination and a real
  DNS name instead of a raw LoadBalancer IP.
- **Blue/green or canary** rollouts (Argo Rollouts / Flagger).
- **GitOps** (Argo CD / Flux) instead of push-based `kubectl apply`.
- **Policy-as-code** (Azure Policy / OPA Gatekeeper) and `tfsec`/`checkov` in CI.
- **Private ACR/Key Vault endpoints** and a fully private AKS API server.
- **Load/perf tests** and SLO-based alerting with error budgets.
- **Secret rotation** automation and database credential rotation via Key Vault.
