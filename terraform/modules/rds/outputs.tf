output "instance_id" {
  value = huaweicloud_rds_instance.this.id
}

output "private_host" {
  value = huaweicloud_rds_instance.this.private_ips[0]
}

output "port" {
  value = 3306
}

output "database_name" {
  value = var.db_name
}

# The CSMS secret name the app pods resolve at runtime (no secret value exposed).
output "app_credentials_secret_name" {
  value = huaweicloud_csms_secret.db.name
}

output "kms_key_id" {
  value = local.kms_id
}
