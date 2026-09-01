# Cashonrails — DevOps/Platform Engineer Assessment

Production environment for the supplied Laravel REST API on **Huawei Cloud**, provisioned with Terraform and evolved into a reusable internal platform.

**Author:** Moses Boriowo

> Prior Huawei Cloud familiarity is not assumed — the solution maps a well-understood architecture onto Huawei services and explains the trade-offs. Region/AZ/flavor codes are placeholders to confirm in-console and are flagged as assumptions.

---

## Contents
```
assessment/
├── terraform/         # modular IaC: modules/ + envs/{staging,prod}
├── deploy/helm/       # reusable "golden path" service chart
├── ci-cd/             # build → scan → publish → deploy → verify → rollback
├── docs/
│   ├── architecture/              # design + decisions + diagram
│   ├── platform-design/           # Part 2 — the paved road
│   ├── security-data-residency/   # Part 3 — security model + CBN residency
│   └── reliability/               # Part 4 — failure modes, RPO/RTO, DR
└── README.md
```

## Architecture (one line)
Client → **ELB (TLS)** → **NGINX ingress** in **CCE (K8s)** → Laravel pods → **RDS MySQL** + **DCS Redis** + **OBS**; secrets in **CSMS/KMS**; logs/metrics to **LTS/Cloud Eye**; everything residency-pinned to Nigeria. Full detail in [`docs/architecture`](docs/architecture/architecture.md).

## Prerequisites
- Terraform ≥ 1.10, a Huawei Cloud account, and credentials exported as `HW_ACCESS_KEY` / `HW_SECRET_KEY` (never committed).
- A **bootstrapped OBS state bucket** per environment (`cor-tfstate-<env>`), versioned + encrypted — created once, since Terraform can't store its own state in a bucket it hasn't created yet.
- `TF_VAR_node_password` and `domain_name` provided via environment/CI, not tfvars.

## Deploy / destroy
```bash
cd terraform/envs/staging
terraform init
terraform fmt -check -recursive ../..
terraform validate
terraform plan            # review — nothing out-of-region should appear
terraform apply
# ... app is deployed by the CI/CD pipeline (ci-cd/cd-pipeline.yml)
terraform destroy         # tear down
```
Production is the same commands in `terraform/envs/prod` (multi-AZ, requires approval).

## Assumptions
- Huawei's **Nigerian data centre** exposes the managed services used (RDS/OBS/DCS/CSMS/KMS/SWR/LTS/Cloud Eye). Region (`af-north-1`), AZ, and flavor codes are **placeholders to verify**.
- App verified against `Cashonrails/my-assessment-api`: **FrankenPHP on :8080**, `/api/v1/health` + `/api/v1/ready`, `stderr` logging. SQLite→RDS is a **config-only** change (`DB_CONNECTION=mysql`).
- Some Huawei resource attribute names may differ by provider version and are commented where they should be confirmed.

## Known limitations (honest)
- **State locking:** OBS has no DynamoDB equivalent; I use Terraform's S3-native lockfile (`use_lockfile`) as best-effort and document it — verify OBS supports it, else use a CI mutex.
- Terraform is written to **plan-clean** and demonstrate structure/judgement; it is **not applied against a live Huawei account** in this timebox, so exact flavor/region codes need console confirmation before a real apply.
- Not every capability is fully implemented (per the brief) — priorities were IaC, architecture, CI/CD, security, and residency; see each doc's "what I'd add with more time."

## Cost drivers & cost-conscious choices
- **Drivers:** CCE control plane + nodes, RDS (multi-AZ ≈ 2×), ELB, NAT gateway, OBS, inter-AZ/egress transfer.
- **Choices:** staging is single-AZ with smaller nodes and a lower autoscaler ceiling; non-prod can scale to zero; OBS lifecycle expires old versions; one shared NAT. Favour engineering quality over spend (brief guidance).

## Production improvements with more time
Progressive delivery (Argo Rollouts), OPA/Gatekeeper guardrails as code, a `service-infra` module + self-service CLI/Backstage, scheduled DR restore drills + chaos tests, OpenTelemetry tracing, and cost dashboards with anomaly alerts.

## Evaluation-criteria map
| Area (weight) | Where |
|---|---|
| Architecture & judgement (15%) | `docs/architecture` |
| Terraform / IaC (20%) | `terraform/` (modules + envs) |
| CI/CD & deployment (15%) | `ci-cd/`, `deploy/helm` |
| Security, IAM, secrets, networking (15%) | `docs/security-data-residency` §A, `modules/{iam,vpc,rds}` |
| Reliability, backup, DR (10%) | `docs/reliability` |
| Observability (10%) | architecture §4.10, reliability |
| Platform engineering / DevEx (10%) | `docs/platform-design`, `deploy/helm` |
| Data residency (5%) | `docs/security-data-residency` §B |
