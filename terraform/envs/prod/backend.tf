# ---------------------------------------------------------------------------
# Remote state on Huawei OBS (S3-compatible), pinned to the Nigerian location
# so that Terraform state — which contains resource metadata — also satisfies
# the CBN data-residency boundary (see docs/security-data-residency).
#
# NOTE ON LOCKING: the AWS s3 backend normally uses DynamoDB for state locking,
# which OBS does not provide. Terraform >= 1.10 supports S3-native lockfiles
# (use_lockfile); OBS support for this is not guaranteed. Locking strategy and
# this limitation are documented honestly in terraform/README.md. State bucket
# is created once via the bootstrap step, then referenced here.
# ---------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket = "cor-tfstate-prod" # created during bootstrap, versioning + encryption on
    key    = "prod/terraform.tfstate"
    region = "af-north-1" # ASSUMPTION: Nigeria region code — verify against Huawei console

    endpoints = {
      s3 = "https://obs.af-north-1.myhuaweicloud.com"
    }

    # OBS is S3-compatible but not AWS — skip AWS-specific validations.
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_lockfile                = true # best-effort S3-native lock; see README limitation
  }
}
