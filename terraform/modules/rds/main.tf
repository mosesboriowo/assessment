# ---------------------------------------------------------------------------
# RDS for MySQL — production replacement for the app's dev-only SQLite
# (docs/architecture §2.1). Private-data subnet only, KMS-encrypted at rest,
# automated backups + PITR.
#
# The application does NOT use a static DB password. Vault's database secrets
# engine (docs/architecture §4.6) connects with the admin credential below and
# mints SHORT-LIVED, per-pod MySQL users, auto-rotated and revoked on lease end.
# The admin credential is generated here and consumed by Vault at bootstrap — it
# is never stored in CSMS (region-scoped → residency gap) or in Git.
# ---------------------------------------------------------------------------

# Admin password is generated, not human-written. It lands in Terraform state
# (remote, encrypted) and is loaded into Vault at bootstrap; the app never sees it.
resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#%*_-+"
}

# KMS key for disk encryption at rest (created here; can be centralised later).
resource "huaweicloud_kms_key" "db" {
  count        = var.kms_key_id == "" ? 1 : 0
  key_alias    = "${var.name_prefix}-rds-kms"
  pending_days = "7"
}

locals {
  kms_id = var.kms_key_id != "" ? var.kms_key_id : huaweicloud_kms_key.db[0].id
}

resource "huaweicloud_rds_instance" "this" {
  name                = "${var.name_prefix}-mysql"
  flavor              = var.flavor
  vpc_id              = var.vpc_id
  subnet_id           = var.subnet_id
  security_group_id   = var.security_group_id
  availability_zone   = var.availability_zones
  ha_replication_mode = var.multi_az ? "async" : null

  db {
    type     = "MySQL"
    version  = "8.0"
    port     = 3306
    password = random_password.admin.result # RDS admin ("root")
  }

  volume {
    type               = "CLOUDSSD"
    size               = var.volume_size
    disk_encryption_id = local.kms_id # encryption at rest via KMS
  }

  backup_strategy {
    start_time = "02:00-03:00" # off-peak window
    keep_days  = var.backup_keep_days
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [availability_zone] # AZ order can be reordered by the API
  }
}

# The application database. Application USER accounts are created dynamically by
# Vault's DB engine, so no static application account is provisioned here.
# (In production, Vault would connect via a dedicated, minimally-privileged
# management account rather than root.)
resource "huaweicloud_rds_mysql_database" "app" {
  instance_id   = huaweicloud_rds_instance.this.id
  name          = var.db_name
  character_set = "utf8mb4"
}
