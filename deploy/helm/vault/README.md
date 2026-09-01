# Self-hosted Vault — in-country secrets

Vault replaces Huawei CSMS/KMS for **residency-bound secrets**, because CSMS/KMS are region-scoped (Johannesburg) and would place secrets/keys outside Nigeria. Vault runs **on CCE in the Nigerian AZ** with its data on a PVC, so secrets stay in-country and Vault stays cloud-agnostic (portable to on-prem for the hybrid model).

## Topology
- **3-node Raft HA** (StatefulSet). Quorum = 2 → tolerates one node loss. *(Two nodes cannot keep quorum — that is why it is 3, not 2.)*
- **PVC per pod** on **Huawei EVS SSD**, AZ-pinned to Nigeria.
- **Pod anti-affinity** so the three replicas land on different nodes.

## No manual-unseal ("no steady seal problem") → auto-unseal
Pods restart without a human unsealing Vault, via **auto-unseal**:
- **Transit auto-unseal (chosen):** a small, separate **in-country "unseal" Vault** exposes the Transit engine; the main Vault uses it to unseal automatically. Open-source, cloud-agnostic, stays in Nigeria. The unseal Vault is bootstrapped once (it can itself use a single-node + KMS/HSM or a sealed-restart-rare pattern).
- **Alternative (bank-grade):** **Dedicated HSM + PKCS#11** auto-unseal — hardware-backed, but **Vault Enterprise** + Huawei DHSM.
- **Not available:** a native Huawei KMS seal (Vault has no Huawei provider) — only usable if Huawei KMS offers an AWS-KMS-compatible endpoint (`awskms` seal) — verify.

Initialise once, then it is hands-off:
```bash
vault operator init      # capture recovery keys + root token, store offline/split
# with auto-unseal, subsequent pod restarts unseal automatically — no manual step
```

## Auth: AD for people, Kubernetes for workloads
- **Humans (operators):** LDAP/AD (or OIDC/Entra ID) auth — engineers log in with AD credentials; Vault maps **AD groups → policies**. Central identity + audit + easy offboarding.
  ```bash
  vault auth enable ldap
  vault write auth/ldap/config url="ldaps://ad.internal" ...
  vault write auth/ldap/groups/platform-admins policies="platform-admin"
  ```
- **App pods (workloads):** **Kubernetes auth method** — a pod presents its service-account token, Vault verifies it with the cluster and returns a scoped token. **AD is not used for pods.**
  ```bash
  vault auth enable kubernetes
  vault write auth/kubernetes/role/cashonrails-api \
    bound_service_account_names=cashonrails-api \
    bound_service_account_namespaces=staging \
    policies=cashonrails-api ttl=1h
  ```

## How the app gets its secrets
The **Vault Agent injector** (enabled in values) injects secrets into the Laravel pod at runtime. The golden-path chart references a synced secret (`envFromSecret`); with Vault, that secret is produced by the agent/CSI from Vault — nothing sensitive in Git, images, or Terraform.

**Dynamic DB credentials (a Vault win):** instead of a static MySQL password, Vault's **database secrets engine** issues a **short-lived, per-pod credential** that is auto-rotated and revoked on lease expiry:
```bash
vault secrets enable database
vault write database/roles/cashonrails-api \
  db_name=mysql creation_statements="CREATE USER ..." default_ttl=1h max_ttl=24h
```

## StorageClass (residency)
Create/confirm an EVS SSD StorageClass bound to the **Nigerian AZ** so Raft data cannot land in Johannesburg:
```yaml
# evs-ssd-nigeria-az (illustrative)
allowedTopologies:
  - matchLabelExpressions:
      - key: failure-domain.beta.kubernetes.io/zone
        values: ["<nigerian-az-code>"]
```

## Deploy
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm upgrade --install vault hashicorp/vault \
  -n vault --create-namespace -f deploy/helm/vault/values.yaml
```

## Trade-off (for the presentation)
CSMS is managed (no ops) but region-scoped → residency gap. Vault is self-hosted (I run HA/Raft, auto-unseal, upgrades, backups) but **in-country, dynamic-secret-capable, AD-integrated, and cloud-agnostic**. Since residency already forces self-hosting, Vault is the residency- and security-preferred choice; CSMS remains fine for non-residency-bound config.
