# ---------------------------------------------------------------------------
# OBS — object storage for application data (Laravel filesystem driver). It is
# versioned, KMS-encrypted, and created in the Nigerian location so its contents
# stay in-country (docs/security-data-residency). Private; no public access.
# The Terraform remote-state bucket is bootstrapped separately (see README) to
# avoid the chicken-and-egg of storing state in a bucket Terraform must create.
# ---------------------------------------------------------------------------

resource "huaweicloud_obs_bucket" "app" {
  bucket        = "${var.name_prefix}-app-data"
  acl           = "private"
  storage_class = "STANDARD"
  encryption    = true
  kms_key_id    = var.kms_key_id

  versioning = true

  # Expire old object versions to control cost; residency is preserved in-region.
  lifecycle_rule {
    name    = "expire-noncurrent"
    enabled = true
    noncurrent_version_expiration {
      days = var.noncurrent_version_days
    }
  }

  tags = var.tags
}
