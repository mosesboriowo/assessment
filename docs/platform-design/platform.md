# Platform Design — the paved road (Part 2)

**Goal:** the Laravel API is the *first* service, not the only one. Teams work across PHP/Laravel, Go, Java/Spring, Node/Next, TypeScript. The platform lets any team deploy consistently and safely **without building one-off infrastructure per service.**

The core idea: the Part 1 solution is already **90% reusable**. A new service reuses the shared cluster, network, pipeline template, and Helm golden-path chart, and provides only the ~10% that is genuinely its own (its image, config, and scaling numbers).

---

## What the platform provides (reused by every service)

| Capability | How it is shared |
|---|---|
| **Compute** | One **CCE** cluster; each service is a namespace + Deployment. No new cluster per service. |
| **Reusable Terraform modules** | `vpc`, `rds`, `dcs`, `obs`, `iam`, `cce`, `elb` — a team composes them, or a new `service-infra` module wraps "DB + secret + namespace" as one call. |
| **CI/CD template** | `ci-cd/cd-pipeline.yml` is parameterised (image name, chart values). A new service copies ~10 lines, not a pipeline. |
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

A team creates a service by providing three things and running one command:
1. A **Dockerfile** (their image).
2. A **`values.yaml`** (name, port, health paths, scaling).
3. A **service manifest** declaring what backing services it needs (e.g. `database: mysql`, `cache: redis`).

The platform then, via the shared module + pipeline, provisions the namespace, a database + Vault DB role (dynamic creds), the workload identity, and wires the golden-path chart. The safe path is the easy path — teams don't touch raw Terraform or Kubernetes for the common case.

---

## Scenario: a Go payment service joins tomorrow

**What they reuse (≈ everything):**
- The **CCE cluster**, **VPC/networking**, **ELB/ingress**, **observability**, **secrets/IAM patterns**, the **CI/CD template**, and the **golden-path Helm chart** — Go is just a different container. FrankenPHP-vs-Go is irrelevant to the platform; both are HTTP containers with health endpoints.

**What they must provide:**
1. A **Dockerfile** producing a container that listens on a port and exposes **liveness + readiness** endpoints (readiness should check its own dependencies, like our `/api/v1/ready` does).
2. A **`values.yaml`** (image, `containerPort`, probe paths, scaling targets).
3. A **service manifest** requesting backing resources (its own MySQL DB + Redis, provisioned by the shared `rds`/`dcs` modules into the shared instances or dedicated ones per policy).
4. Their **pipeline stub** (10 lines pointing the shared template at their image + chart).

**They do NOT build:** networking, TLS, cluster, secret store, observability, IAM plumbing, or a bespoke pipeline. That is the difference between a paved road and repeatedly paving dirt.

**Guardrails still apply automatically:** image scanning, resource limits, readiness probe, no public data tier, secrets from Vault (K8s auth) — enforced by the pipeline and OPA policies, so a new team can't accidentally ship something insecure.

---

## What I'd add with more time
- A `service-infra` Terraform module and a `platform-cli`/Backstage template so self-service is one command.
- OPA/Gatekeeper policy bundle committed as code with tests.
- A shared observability library (structured-log format + trace propagation) so every language emits consistent telemetry.
