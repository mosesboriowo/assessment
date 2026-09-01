# GitOps paved road — `csh-product`

Every product service is deployed by **Argo CD** from this repo. A team never
runs `kubectl` or `helm` against the cluster; they commit a values file and Argo
reconciles the cluster to match.

## The layout

```
csh-product/
  stg/values/<app>.yml          # staging config for <app>
  production/values/<app>.yml   # production config for <app>
deploy/
  helm/service/                 # the ONE shared golden-path chart
  argocd/
    project.yaml                # AppProject (allowed repo + destinations)
    applicationset.yaml         # the engine: one file -> one Application
    bootstrap.yaml              # app-of-apps root (applied once by hand)
```

## Onboard a new service (e.g. `enyo`) — one file

Staging:

```bash
# create csh-product/stg/values/enyo.yml, commit, push
```

That commit alone makes Argo:

1. create namespace `enyo-stg`,
2. render the golden-path chart → **Deployment, Service, Ingress, HPA**,
3. create the **Vault Secrets Operator** syncs (`enyo-db` dynamic creds, `enyo-kv` static KV) → mounted via `envFrom`,
4. run the **PreSync migration** hook,
5. roll out with readiness-gated traffic.

Production is the same file under `csh-product/production/values/enyo.yml` →
namespace `enyo-production`. **Delete the file → Argo prunes the service.**

## Naming derived by the ApplicationSet

| File | Argo Application | Namespace |
|---|---|---|
| `csh-product/stg/values/enyo.yml` | `stg-enyo` | `enyo-stg` |
| `csh-product/production/values/enyo.yml` | `production-enyo` | `enyo-production` |

## How releases flow (no kubeconfig in CI)

CI (`ci-cd/cd-pipeline.yml`) builds → scans → pushes the image to SWR, then
**commits the immutable SHA into `csh-product/stg/values/<app>.yml`**. Argo sees
the commit and syncs. Promotion to prod is a human-approved commit copying that
proven SHA into the production values file. The git history is the release log;
rollback is `git revert`.

## One-time platform setup (not per app)

- Install Argo CD in the cluster, then `kubectl apply -f deploy/argocd/bootstrap.yaml`.
  After that, the project + ApplicationSet are self-managed by GitOps.
- Install the **Vault Secrets Operator** and create a shared `VaultAuth`
  (named `vault-auth`) + `VaultConnection` pointing at in-country Vault
  (`deploy/helm/vault`), using the Kubernetes auth method.
- Enforce guardrails with OPA/Gatekeeper (no `:latest`, resource limits,
  readiness probe required, no public data tier).

## Prerequisites a service must meet

An HTTP container that listens on a port and exposes **liveness + readiness**
(readiness checks its own deps, like `/api/v1/ready`). Everything else —
networking, TLS, cluster, secret store, observability, IAM — is provided.
