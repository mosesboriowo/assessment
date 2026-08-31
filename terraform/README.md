# Terraform — CashOnRails assessment

Infrastructure for the Laravel API on Huawei Cloud, provisioned as reusable modules composed per environment.

## Layout
```
terraform/
├── modules/
│   ├── vpc/     ✅ network + 3-tier segmentation + NAT
│   ├── rds/     ✅ MySQL (SQLite replacement), private, KMS, dedicated app user
│   ├── dcs/     ✅ Redis, private, password-auth
│   ├── obs/     ▫ object storage + remote-state bucket   (next)
│   ├── iam/     ▫ least-priv users + CCE workload agency (next)
│   ├── cce/     ▫ managed Kubernetes + node pool          (next)
│   └── elb/     ▫ load balancer + TLS                     (next)
└── envs/
    ├── staging/ ✅ composes modules; single-AZ, cost-lean
    └── prod/    ▫ same modules, multi-AZ, larger sizing
```

**Design principle:** environments are *compositions of the same modules with
different inputs* (`envs/staging` vs `envs/prod`). Reuse, consistency, and a
small blast radius per environment (separate state) all come from this.

## Prerequisites
- Terraform >= 1.6
- Huawei Cloud credentials in the environment (never committed):
  ```
  export HW_ACCESS_KEY=...
  export HW_SECRET_KEY=...
  ```
- A one-time **bootstrap** to create the OBS state bucket (`cor-tfstate-<env>`,
  versioning + encryption on) before `init`. Bootstrapping the state store is
  the one action allowed outside Terraform.

## Usage
```bash
cd terraform/envs/staging
terraform init
terraform fmt -check      # style gate (also enforced in CI)
terraform validate        # schema/consistency gate
terraform plan            # review before apply
terraform apply           # provision
terraform destroy         # tear down
```

## State management
- Remote state in **OBS** (S3-compatible), pinned to the **Nigerian location**
  so state metadata stays within the residency boundary.
- Versioning + encryption enabled on the state bucket.
- **Locking limitation (documented honestly):** the AWS `s3` backend normally
  locks via DynamoDB, which OBS does not offer. I enable `use_lockfile` (S3-native
  locking, Terraform ≥ 1.10) as best-effort; if OBS does not honour it, the
  mitigation is **serialised applies through a single CI pipeline** (no local
  applies to shared envs) plus branch protection on the infra repo. In a real
  engagement I would confirm OBS lock support or move state to a locking-capable
  backend located in-country.

## Key assumptions to verify
- **Region code** for the Nigerian location (`af-north-1` used as a placeholder)
  — confirm the actual code and the OBS/ RDS/ CCE service availability there
  (see docs/security-data-residency).
- Provider version `~> 1.70` — pin to the version validated during the build.

## Security notes
- No credentials or secrets in code or state inputs.
- Databases live only in the private-data subnet; no public IP, no internet route.
- Security groups start from deny-all (`delete_default_rules = true`) and open
  only the required ports between tiers.
