# ---------------------------------------------------------------------------
# RDS for MySQL — the production replacement for the app's dev-only SQLite
# (docs/architecture §2.1). Private-data subnet only, KMS-encrypted at rest,
# automated backups + PITR, optional multi-AZ HA. The app connects via a
# dedicated least-privilege account whose credentials live in CSMS, never Git.
# ---------------------------------------------------------------------------

# Passwords are generated, not written by a human. They land in Terraform state,
# which is remote, encrypted, and residency-pinned (see backend + README).
resource "random_password" "root" {
  length           = 24
  special          = true
  override_special = "!#%*_-+"
}

resource "random_password" "app" {
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
    password = random_password.root.result
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

# Dedicated application database + least-privilege account (app never uses root).
resource "huaweicloud_rds_mysql_database" "app" {
  instance_id   = huaweicloud_rds_instance.this.id
  name          = var.db_name
  character_set = "utf8mb4"
}

resource "huaweicloud_rds_mysql_account" "app" {
  instance_id = huaweicloud_rds_instance.this.id
  name        = var.db_user
  password    = random_password.app.result
}

resource "huaweicloud_rds_mysql_database_privilege" "app" {
  instance_id = huaweicloud_rds_instance.this.id
  db_name     = huaweicloud_rds_mysql_database.app.name

  users {
    name     = huaweicloud_rds_mysql_account.app.name
    readonly = false
  }
}

# App credentials in CSMS — the Laravel pods read these at runtime (via workload
# identity), so nothing sensitive is baked into images, env files, or Git.
resource "huaweicloud_csms_secret" "db" {
  name       = "${var.name_prefix}/rds/app"
  kms_key_id = local.kms_id
  secret_text = jsonencode({
    DB_CONNECTION = "mysql"
    DB_HOST       = huaweicloud_rds_instance.this.private_ips[0]
    DB_PORT       = 3306
    DB_DATABASE   = var.db_name
    DB_USERNAME   = var.db_user
    DB_PASSWORD   = random_password.app.result
  })
}
