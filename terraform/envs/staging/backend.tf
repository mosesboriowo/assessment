# ---------------------------------------------------------------------------
# Remote state on Huawei OBS (S3-compatible). OBS is region-scoped (af-south-1),
# so state physically resides in the region (South Africa), not the Nigerian AZ —
# a residency gap flagged below and mitigated in-country (see residency doc).
#
# NOTE ON LOCKING: the AWS s3 backend normally uses DynamoDB for state locking,
# which OBS does not provide. Terraform >= 1.10 supports S3-native lockfiles
# (use_lockfile); OBS support for this is not guaranteed. Locking strategy and
# this limitation are documented honestly in terraform/README.md. State bucket
# is created once via the bootstrap step, then referenced here.
# ---------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket = "cor-tfstate-staging" # created during bootstrap, versioning + encryption on
    key    = "staging/terraform.tfstate"
    region = "af-south-1" # Southern-Africa region (Johannesburg); the Nigerian AZ is within it

    endpoints = {
      s3 = "https://obs.af-south-1.myhuaweicloud.com"
    }

    # RESIDENCY NOTE: OBS is a *region-scoped* service, so this state bucket lives
    # in the af-south-1 region (physically South Africa), NOT the Nigerian AZ.
    # Terraform state is therefore a residency GAP under strict CBN reading — the
    # in-country mitigation is to hold state on an in-country DC/on-prem backend
    # (see docs/security-data-residency §B.0/§B.4).

    # OBS is S3-compatible but not AWS — skip AWS-specific validations.
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_lockfile                = true # best-effort S3-native lock; see README limitation
  }
}
