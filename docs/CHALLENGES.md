# Challenges & Resolutions

Notable challenges encountered while building the platform and how they were
resolved.

## 1. Modeling "public/private subnets" on Azure

**Challenge.** The design calls for public and private subnets. Azure subnets
are not intrinsically public or private the way AWS subnets are (there is no
route-table-to-IGW distinction by default).

**Resolution.** Modeled the tiers explicitly with **NSGs** and topology: a
public/ingress subnet that permits inbound 80/443, a private AKS subnet that
denies inbound internet traffic, and a delegated DB subnet reachable only from
AKS on 5432. PostgreSQL uses **private VNet integration** with a private DNS
zone — no public endpoint.

## 2. Terraform module dependency cycle for alerts

**Challenge.** The `monitoring` module creates the Log Analytics and Prometheus
workspaces that the `aks` module consumes. Placing the AKS/DB **metric alerts**
inside `monitoring` created a cycle: `monitoring → aks → monitoring`.

**Resolution.** Kept the workspaces and action group in the `monitoring` module
but moved the metric-alert resources to the **root module**, where they can
reference `module.aks.cluster_id`, `module.database.server_id` and
`module.monitoring.action_group_id` without a cycle.

## 3. Managed Prometheus wiring on AKS

**Challenge.** Enabling the `monitor_metrics` addon on the AKS cluster alone does
not route metrics to the Azure Monitor workspace.

**Resolution.** Added the full data-collection pipeline in the `aks` module: a
**Data Collection Endpoint**, a **Data Collection Rule** with the
`Microsoft-PrometheusMetrics` stream targeting the monitor account, and a
**DCR association** to the cluster. A `PodMonitor` CR then selects the app pods.

## 4. Getting secrets into pods without hardcoding

**Challenge.** The app needs the DB password, but secrets must not live in
images, ConfigMaps or Git.

**Resolution.** **Key Vault + Secrets Store CSI driver + workload identity**. A
user-assigned identity is federated to the AKS OIDC issuer and bound to the
`app/todo-api` service account; the CSI `SecretProviderClass` mounts the Key
Vault secret and syncs it into a Kubernetes Secret consumed as `PGPASSWORD`.

## 5. Placeholder substitution across environments

**Challenge.** The Kustomize overlays need per-environment values that only exist
after `terraform apply` (PG host, workload identity client id, Key Vault name,
tenant id).

**Resolution.** Overlays use `__PLACEHOLDER__` tokens; the CD composite action
substitutes them from GitHub environment variables (populated from Terraform
outputs) and pins the image with `kustomize edit set image` before `kubectl
apply`. This keeps environment specifics out of Git while remaining
declarative.

## 6. Chicken-and-egg with Terraform remote state

**Challenge.** Remote state needs a storage account, but creating that with the
same configuration would require the state that doesn't exist yet.

**Resolution.** A separate `terraform/bootstrap` configuration (local state)
provisions the state storage account/container once and prints the exact
`terraform init -backend-config=...` command for the main config.

## 7. Fast PR feedback vs. realistic integration tests

**Challenge.** Unit tests must be fast and dependency-free on PRs, but
integration tests need a real database.

**Resolution.** Split the suites: unit tests **mock** the `db` module; the CI
integration job spins up a **PostgreSQL service container** and runs the real
SQL/HTTP path with `--runInBand`. Both gate the PR.

## 8. Non-root, read-only containers breaking writes

**Challenge.** Hardening the pod (`readOnlyRootFilesystem`, `runAsNonRoot`) can
break apps that write to disk.

**Resolution.** The app is stateless and logs to stdout, so a read-only root FS
works as-is. The Key Vault secret is mounted read-only via CSI. Verified probes
and startup still pass under the restricted `securityContext`.
