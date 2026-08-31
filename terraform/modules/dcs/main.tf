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

# Redis credentials in CSMS, consumed by the app at runtime.
resource "huaweicloud_csms_secret" "redis" {
  name       = "${var.name_prefix}/dcs/app"
  kms_key_id = var.kms_key_id != "" ? var.kms_key_id : null
  secret_text = jsonencode({
    REDIS_HOST     = huaweicloud_dcs_instance.this.private_ips[0]
    REDIS_PORT     = huaweicloud_dcs_instance.this.port
    REDIS_PASSWORD = random_password.redis.result
    REDIS_CLIENT   = "phpredis"
  })
}
