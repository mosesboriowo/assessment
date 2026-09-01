# Security & Data Residency (Part 3)

Two things live here: the **security model** (IAM, secrets, networking, encryption, backups, auditability) and the **CBN data-residency** approach. Huawei operates a **local data centre in Nigeria**, so residency is satisfiable in-cloud — but, as the brief warns, *picking a region is not the same as satisfying residency.* The work is proving every data class stays in-country and being able to prevent/detect leakage.

---

## Part A — Security model

### Network
- 3-tier VPC: **public** (ELB/NAT only), **private app** (CCE nodes/pods), **private data** (RDS/DCS). Data tier has **no public IP and no internet route**.
- Least-privilege **security groups**: ELB→ingress:443, ingress→pods, pods→RDS:3306, pods→DCS:6379. Default-deny elsewhere.
- The database is **never publicly exposed** (brief requirement).

### Identity & access
- **Workload identity (agency)** for pods → they read only their own CSMS secrets and OBS bucket; **no static keys in images**.
- **Scoped CI/CD role** (push to SWR, deploy to CCE) — no admin, no console.
- Human admin via SSO/console, MFA, out of band from workloads.

### Secrets & encryption
- All credentials are **generated** (`random_password`) and stored in **CSMS**, encrypted with **KMS**. Pods consume them at runtime. **Nothing sensitive in Git, images, or tfvars.**
- **Encryption at rest** (KMS) on RDS, OBS, and DCS credentials; **TLS in transit** everywhere (ELB→ingress→service; app→RDS/DCS over TLS).

### Auditability
- **CTS (Cloud Trace Service)** records all control-plane API calls (who created/changed what).
- Application + audit logs to **LTS** (structured JSON), retained in-country.

### Guardrails (what is *prevented*)
Avoided by design (matching the brief's prohibited list): committed secrets, plaintext creds in Terraform, public databases, over-broad IAM, manually provisioned infra, and disabling controls to "make it work." Enforced going forward by OPA/Gatekeeper policy.

---

## Part B — Data residency (CBN)

**Residency boundary:** designated production customer and transaction data must remain in Nigeria. I extend that boundary to **every data class that could contain or reveal that data**, because the DB being in-country is not sufficient on its own.

### B.1 Residency verification matrix

| # | Data class | Huawei service | Location control | In Nigeria? |
|---|---|---|---|---|
| 1 | Customer/transaction DB | RDS (MySQL) | provisioned in NG DC | ✅ by design |
| 2 | DB backups / snapshots / PITR | RDS backup | keep backups in same region; disable cross-region copy | ✅ (verify no cross-region default) |
| 3 | Object / file data | OBS bucket | bucket created in NG | ✅ by design |
| 4 | Cache data (may hold PII in transit) | DCS (Redis) | provisioned in NG DC | ✅ by design |
| 5 | Application + **audit logs** | LTS | log project pinned to NG | ⚠️ verify LTS runs in NG DC |
| 6 | **Monitoring / telemetry** | Cloud Eye / AOM | region-scoped project | ⚠️ verify telemetry not sent to a central region |
| 7 | **Secrets / encryption keys** | CSMS / KMS | keys created in NG | ⚠️ verify CSMS/KMS available in NG DC |
| 8 | Container images + metadata | SWR | registry in NG; disable cross-region replication | ⚠️ verify SWR in NG + no replication |
| 9 | **DR copies** | RDS/OBS cross-AZ | must be **another Nigerian** AZ/DC, not another country | ✅ if 2nd NG AZ exists (else contingency) |
| 10 | **Terraform state** | OBS state bucket | bucket in NG (backend endpoint = NG OBS) | ✅ by design |

> The ⚠️ rows are the real test: a naïve design leaks logs, telemetry, keys, or image copies out of country by default. Each is called out so it is verified, not assumed.

### B.2 Which services / locations
- Compute (CCE), DB (RDS), cache (DCS), storage (OBS), secrets (CSMS/KMS), registry (SWR), logging (LTS), monitoring (Cloud Eye/AOM) — **all pinned to the Nigerian location** (region + explicit resource placement).
- DR: a second **Nigerian** AZ/DC (never a foreign region), so DR itself stays compliant.

### B.3 Assumptions
1. Huawei's Nigerian DC exposes the **specific managed services** above (RDS/OBS/DCS/CSMS/KMS/SWR/LTS/Cloud Eye). Region and AZ codes (`af-north-1`, AZs) are **placeholders to confirm** in the console.
2. Backups/replication default to **in-region** unless configured otherwise (I disable any cross-region option).

### B.4 Services I could not fully verify
- **LTS, Cloud Eye/AOM, CSMS/KMS, SWR** in-country availability and whether they store any metadata/telemetry outside the NG DC. **Mitigation if unavailable:** self-host the equivalent in-country (e.g. Prometheus/Grafana + ELK on CCE for observability/logs; Vault for secrets), keeping that data on Nigerian infrastructure. This is where the **hybrid/on-prem contingency** applies.

### B.5 How I technically prevent / detect data leaving Nigeria
**Prevent (policy):**
- An **IAM/organisation policy that denies resource creation outside the approved Nigerian region** (region-restriction condition) — nobody can `terraform apply` a resource elsewhere.
- Explicit region/AZ on **every** resource; backups/snapshots/replication set to in-region only.
- OPA/Gatekeeper denies workloads that reference out-of-region endpoints.

**Detect (audit):**
- **CTS** trails + a scheduled check that flags any resource whose location ≠ Nigeria (using the `residency = nigeria` tag as the audit key).
- Config/compliance rule: alert via SMN if a bucket, DB, snapshot, or log project is created outside the boundary.
- Terraform `plan` in CI is itself a detector — a diff placing anything out-of-region fails review.

---

## Summary
Residency is satisfied **in-country on Huawei Cloud**, with every data class — including the easily-missed ones (logs, telemetry, keys, image metadata, DR copies, Terraform state) — pinned to Nigeria, **policy that prevents** out-of-region creation, and **audit that detects** it. Services whose in-country availability I cannot confirm are documented with an in-country self-hosted mitigation rather than assumed compliant.
