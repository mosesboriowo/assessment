output "instance_id" {
  value = huaweicloud_dcs_instance.this.id
}

output "private_host" {
  value = huaweicloud_dcs_instance.this.private_ips[0]
}

output "port" {
  value = huaweicloud_dcs_instance.this.port
}

output "app_credentials_secret_name" {
  value = huaweicloud_csms_secret.redis.name
}
