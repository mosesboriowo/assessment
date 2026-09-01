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

output "kms_key_id" {
  value = local.kms_id
}

# Admin credential consumed by Vault's database secrets engine at bootstrap so it
# can mint short-lived, per-pod app users. Sensitive; never stored in CSMS or Git.
output "admin_username" {
  value = "root"
}

output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}
