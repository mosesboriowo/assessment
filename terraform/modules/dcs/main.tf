# ---------------------------------------------------------------------------
# DCS (Redis) — shared cache, session and queue backend for the Laravel API so
# that state lives outside the pods and every replica sees the same data
# (docs/architecture §4.3). Private-data subnet, password-authenticated,
# reachable only from the app tier.
# ---------------------------------------------------------------------------

resource "random_password" "redis" {
  length  = 24
  special = false # some Redis clients mishandle certain special chars
}

resource "huaweicloud_dcs_instance" "this" {
  name               = "${var.name_prefix}-redis"
  engine             = "Redis"
  engine_version     = var.engine_version
  capacity           = var.capacity
  flavor             = var.flavor
  availability_zones = var.availability_zones
  vpc_id             = var.vpc_id
  subnet_id          = var.subnet_id
  security_group_id  = var.security_group_id
  password           = random_password.redis.result
  tags               = var.tags
}

# Redis endpoint + password are written to Vault KV at bootstrap (in-country),
# not to region-scoped CSMS. The app reads them from Vault via the Agent/CSI.
# The password is exposed only as a sensitive output for that bootstrap step.
