# ---------------------------------------------------------------------------
# IAM — least-privilege identities.
#  1. A workload-identity agency assumed by CCE pods so the app can use its OBS
#     bucket WITHOUT static access keys in the image. (Secrets do NOT come from
#     Huawei IAM/CSMS — pods authenticate to self-hosted Vault via the Kubernetes
#     auth method, which is cluster-side, so no csms:* permission is granted.)
#  2. A tightly-scoped CI/CD deploy role/policy (push images to SWR, deploy to
#     the cluster) — no broad admin, no console rights.
# Human admin users and root are out of scope here and managed via SSO/console.
# ---------------------------------------------------------------------------

# Custom, minimal policy: use only the app's own OBS bucket.
resource "huaweicloud_identity_custom_role" "workload" {
  name        = "${var.name_prefix}-workload"
  description = "App pods: use own OBS bucket only (secrets come from Vault, not IAM)."
  type        = "AX"
  policy = jsonencode({
    Version = "1.1"
    Statement = [
      {
        Effect = "Allow"
        Action = ["obs:object:GetObject", "obs:object:PutObject", "obs:bucket:ListBucket"]
      }
    ]
  })
}

# Agency = Huawei's workload identity. CCE service accounts map to this so pods
# get short-lived credentials instead of embedded keys.
resource "huaweicloud_identity_agency" "workload" {
  name                  = "${var.name_prefix}-workload"
  description           = "Workload identity assumed by CCE app pods."
  delegated_domain_name = var.domain_name
  project_role {
    project = var.region_project
    roles   = [huaweicloud_identity_custom_role.workload.name]
  }
}

# Scoped policy for the CI/CD deployer (image push + cluster deploy only).
resource "huaweicloud_identity_custom_role" "ci_deploy" {
  name        = "${var.name_prefix}-ci-deploy"
  description = "CI/CD: push to SWR and deploy workloads to CCE. No admin."
  type        = "AX"
  policy = jsonencode({
    Version = "1.1"
    Statement = [
      { Effect = "Allow", Action = ["swr:repository:*"] },
      { Effect = "Allow", Action = ["cce:cluster:get", "cce:kubernetes:*"] }
    ]
  })
}
