# Platform Design — the paved road (Part 2)

**Goal:** The goal is to deploy the Laravel API as the *first* service, which means there will be more services. With the Teams working across PHP/Laravel, Go, Java/Spring, Node/Next, TypeScript. The platform lets any team deploy consistently and safely **without building one-off infrastructure per service.**

The core idea: the Part 1 solution is already **reusable**. A new service reuses the shared cluster, network, pipeline template, and Helm golden-path chart, and provides only the ~10% that is genuinely its own (its image, config, and scaling numbers).

---

## What the platform provides (reuseable by every service)

| Capability | How it is shared |
|---|---|
| **Compute** | One **CCE** cluster; each service is a namespace + Deployment. No new cluster per service. |
| **Reusable Terraform modules** | `vpc`, `rds`, `dcs`, `obs`, `iam`, `cce`, `elb` — a team composes them, or a new `service-infra` module wraps "DB + secret + namespace" as one call. |
| **CI/CD template** | `ci-cd/cd-pipeline.yml` builds/scans/pushes and commits the image SHA into the app's values file. Reused as-is; only image name + values path differ. |
| **GitOps delivery** | **Argo CD** `ApplicationSet` turns any `csh-product/<env>/values/<app>.yml` into a running service. CI never holds cluster creds; `git revert` is rollback. |
| **Golden-path Helm chart** | `deploy/helm/service` renders a production-shaped Deployment/Service/Ingress/HPA/probes/secret-injection from a small `values.yaml`. |
| **Standardised observability** | LTS log project + Cloud Eye/AOM dashboards + SMN alert rules are defined once; a service inherits them by labelling. |
| **Secrets management** | Self-hosted **Vault** (in-country); a service gets `TEAM/SERVICE/*` paths, a Kubernetes-auth role, and **dynamic short-lived DB creds** via the Vault Agent — no static keys. |
| **IAM / workload identity** | One agency pattern; each service's pods assume a scoped identity for its own secrets/bucket only. |
| **Networking standards** | Same 3-tier segmentation and SG conventions; services never expose data tiers. |
| **Security guardrails** | Policy-as-code (OPA/Gatekeeper) enforces: no `latest` tag, resource limits required, no public LoadBalancer on data services, readiness probe required. |
| **Environments** | `terraform/envs/{staging,prod}` pattern; a new env is a new tfvars, not new code. |
| **Deployment strategy** | Rolling by default, canary available; auto-rollback on failed health — identical for all services. |
| **Docs / runbooks** | A service template ships with a README + runbook skeleton. |
| **Platform versioning** | The Helm chart and modules are **semver-versioned and pinned**; a service upgrades deliberately. |

---

## Developer self-service (the paved road)

Deployment is **GitOps via Argo CD** — no team ever runs `kubectl`/`helm` at the cluster. Onboarding a service is **committing one values file** at a fixed path:

```
csh-product/stg/values/<app>.yml          # staging
csh-product/production/values/<app>.yml   # production
```

An Argo CD **ApplicationSet** (`deploy/argocd/applicationset.yaml`) globs `csh-product/*/values/*.yml`; every file that appears becomes one Argo `Application` that renders the shared golden-path chart with that file. So committing `csh-product/stg/values/enyo.yml` alone makes Argo create namespace `enyo-stg` and render **Deployment, Service, Ingress, HPA**, the **Vault Secrets Operator** syncs (dynamic DB creds + static KV → mounted via `envFrom`), and the **PreSync migration** hook — then roll out with readiness-gated traffic. Deleting the file prunes the service. Production is the same file under `csh-product/production/values/`.

What a team provides:
1. A **Dockerfile** — an HTTP container exposing liveness + readiness (readiness checks its own deps, like `/api/v1/ready`).
2. The **`<app>.yml`** values file (image, port, health paths, scaling, its Vault paths).

Releases carry no cluster credentials: CI builds → scans → pushes to SWR, then **commits the immutable image SHA into the staging values file**; Argo syncs from that commit. Promotion to prod is a human-approved commit copying the proven SHA into the production file. The git history is the release log; rollback is `git revert`. See `deploy/argocd/README.md`. The safe path is the easy path — teams don't touch raw Terraform, Argo config, or Kubernetes for the common case.

---

## Scenario: a Go payment service joins tomorrow

**What they reuse (≈ everything):**
- The **CCE cluster**, **VPC/networking**, **ELB/ingress**, **observability**, **secrets/IAM patterns**, the **CI/CD template**, and the **golden-path Helm chart** — Go is just a different container. FrankenPHP-vs-Go is irrelevant to the platform; both are HTTP containers with health endpoints.

**What you need to provide:**
1. A **Dockerfile** producing a container that listens on a port and exposes **liveness + readiness** endpoints (readiness should check its own dependencies, like our `/api/v1/ready` does).
2. A **`csh-product/<env>/values/<app>.yml`** file (image, `containerPort`, probe paths, scaling targets, Vault paths). Committing it is the deploy — Argo does the rest.
3. Backing resources (its own MySQL DB + Redis) provisioned by the shared `rds`/`dcs` modules and exposed through Vault (dynamic DB creds + KV), referenced by the Vault paths in that values file.
4. **No pipeline to write** — they reuse the shared CI template (build/scan/push + commit the SHA into their values file); Argo CD syncs from Git.

**They do NOT build:** networking, TLS, cluster, secret store, observability, IAM plumbing, or a bespoke pipeline. That is the difference between a paved road and repeatedly paving dirt.

**Guardrails still apply automatically:** image scanning, resource limits, readiness probe, no public data tier, secrets from Vault (K8s auth) — enforced by the pipeline and OPA policies, so a new team can't accidentally ship something insecure.

