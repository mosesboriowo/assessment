# Security & Data Residency (Part 3)

Two things live here: the **security model** (IAM, secrets, networking, encryption, backups, auditability) and the **CBN data-residency** approach. Huawei operates a **local data centre in Nigeria**, so residency is satisfiable in-cloud — but, as the brief warns, *picking a region is not the same as satisfying residency.* The work is proving every data class stays in-country and being able to prevent/detect leakage.

---

## Part A — Security model

### Network
- 3-tier VPC: **public** (ELB/NAT only), **private app** (CCE nodes/pods), **private data** (RDS/DCS). Data tier has **no public IP and no internet route**.
- Least-privilege **security groups**: ELB→ingress:443, ingress→pods, pods→RDS:3306, pods→DCS:6379. Default-deny elsewhere.
- The database is **never publicly exposed** (brief requirement).

### Identity & access
- **Workload identity (agency)** for pods → use only their own OBS bucket; **no static keys in images**. Secrets come from **self-hosted Vault** via the Kubernetes auth method (not Huawei IAM/CSMS).
- **Scoped CI/CD role** (push to SWR, deploy to CCE) — no admin, no console.
- Human admin via SSO/console, MFA, out of band from workloads.

### Secrets & encryption
- Application credentials live in **self-hosted Vault** (in-country, HA Raft, auto-unseal): pods authenticate with the **Kubernetes auth method** and get **dynamic, short-lived DB credentials** minted per pod — nothing static. The only Terraform-generated secret is the RDS **admin** password (`random_password`, a sensitive output consumed by Vault's DB engine), never checked in. **Nothing sensitive in Git, images, or tfvars.**
- **Encryption at rest** (KMS) on RDS and OBS; Vault's own storage is encrypted and sealed. **TLS in transit** everywhere (ELB→ingress→service; app→RDS/DCS over TLS; pods→Vault over TLS).

### Auditability
- **CTS (Cloud Trace Service)** records all control-plane API calls (who created/changed what).
- Application + audit logs to **LTS** (structured JSON), retained in-country.

### Guardrails (what is *prevented*)
Avoided by design (matching the brief's prohibited list): committed secrets, plaintext creds in Terraform, public databases, over-broad IAM, manually provisioned infra, and disabling controls to "make it work." Enforced going forward by OPA/Gatekeeper policy.

---

## Part B — Data residency (CBN)

**Residency boundary:** designated production customer and transaction data must remain in Nigeria. I extend that boundary to **every data class that could contain or reveal that data**, because the DB being in-country is not sufficient on its own.

### B.0 Critical finding — Nigeria is an *availability zone*, not a full region
Verifying in-console (and against public information), Huawei Cloud's full **regions** in Africa are **AF-Johannesburg (South Africa)** and **Egypt**. **Nigeria is an availability zone** associated with the Southern-Africa region, added in Huawei's 2024–25 expansion — **not an independent region**. This changes the residency design materially, and is exactly the case the brief warns about ("a single region does not automatically satisfy residency"):

- **Region-scoped services and control-plane metadata physically live in South Africa**, not Nigeria (IAM, and potentially CSMS/KMS, monitoring/telemetry, SWR image metadata). That is residency-relevant data leaving the country.
- **Multi-AZ HA becomes a residency *risk*, not a benefit** — replicating across the region's AZs can place a replica/backup in a **South African** AZ. So multi-AZ RDS/DCS must be reconsidered for residency-bound data.
- **In-country DR is constrained** — with a single Nigerian AZ there is no second in-country AZ for cross-AZ DR.

**Design consequences (applied below):**
1. **AZ-pin** every residency-bound resource to the **Nigerian AZ specifically** (not just the region), accepting **single-AZ** in Nigeria for that data and documenting the **HA trade-off** — I trade cross-AZ HA for compliance because the other AZs are in the wrong country.
2. **Classify each service AZ-pinnable vs region-scoped.** Region-scoped services are **residency gaps** → mitigate by **self-hosting the equivalent in-country** (Vault for secrets, Prometheus/Grafana + ELK on CCE for logs/telemetry, a private registry).
3. **DR in-country** uses an **on-prem/local Nigerian site** (hybrid contingency), since a second in-country cloud AZ may not exist.

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
1. **Nigeria is an AZ under the Southern-Africa region** (per §B.0), so residency-bound resources are **AZ-pinned to the Nigerian AZ** and run **single-AZ** (no cross-AZ HA into South Africa). Region/AZ codes are placeholders to confirm in-console.
2. Which managed services are **AZ-pinnable** (RDS/DCS/OBS should be) vs **region-scoped** (IAM, and to-confirm CSMS/KMS/LTS/Cloud Eye/SWR) needs verification; region-scoped ones are treated as **residency gaps** until proven otherwise.
3. Backups/replication default to **in-region**; I disable cross-region copy and pin snapshots to the Nigerian AZ.

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

### B.6 Cloud landscape — why full residency ultimately implies hybrid
This is **not a Huawei-specific limitation**. No hyperscaler operates a full region in Nigeria: **AWS** has only a small Lagos *Local Zone* (its region is Cape Town); **Azure** and **Google Cloud** are **Johannesburg**-only; Huawei's Nigeria presence is the **AZ** discussed above. Switching cloud provider would not, on its own, satisfy CBN — and Huawei's Nigeria AZ is in fact one of the *closer* in-country cloud options.

Because of this, **complete CBN residency ultimately points to a hybrid model**: general workloads on cloud, and the regulated customer/transaction data (plus its backups, logs, keys, and DR) in an **in-country Nigerian data centre or on-prem** — e.g. Rack Centre, Equinix/MDXi Lagos, Africa Data Centres, or **self-managed bare-metal Kubernetes** in a Nigerian colo. This is precisely why CBN's localisation drive is moving Nigerian fintechs toward local/hybrid infrastructure.

The architecture here is **compatible with that direction, not a dead end**: residency-bound data is already isolated (AZ-pinned, single-AZ) and the region-scoped gaps already use **self-hosted, in-country** components (Vault, Prometheus/Grafana + ELK, a private registry). Relocating those specific components onto a Nigerian DC/on-prem footprint is an **evolution of the same design, not a rewrite** — the Terraform modules and Helm golden path stay the same; only the underlying location of the regulated tier changes.

---

## Summary
Residency for CashOnRails' regulated data is achieved by **AZ-pinning to the Nigerian AZ** (single-AZ, HA traded for compliance), treating **region-scoped services as gaps** with **in-country self-hosted mitigations**, and **on-prem/local DR** — with **policy that prevents** out-of-region creation and **audit that detects** it. Because no hyperscaler has a full Nigerian region, complete residency ultimately implies a **hybrid model**, which this architecture is built to evolve into. Any service whose in-country availability I cannot confirm is documented with a mitigation, never assumed compliant.
