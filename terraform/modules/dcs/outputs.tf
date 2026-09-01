output "instance_id" {
  value = huaweicloud_dcs_instance.this.id
}

output "private_host" {
  value = huaweicloud_dcs_instance.this.private_ips[0]
}

output "port" {
  value = huaweicloud_dcs_instance.this.port
}

# Redis password for the Vault KV bootstrap. Sensitive; never stored in CSMS/Git.
output "redis_password" {
  value     = random_password.redis.result
  sensitive = true
}
