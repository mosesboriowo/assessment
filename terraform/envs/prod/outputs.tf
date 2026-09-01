output "vpc_id" {
  value = module.vpc.vpc_id
}

output "app_subnet_id" {
  value = module.vpc.app_subnet_id
}

output "data_subnet_id" {
  value = module.vpc.data_subnet_id
}

output "app_security_group_id" {
  value = module.vpc.app_security_group_id
}

output "data_security_group_id" {
  value = module.vpc.data_security_group_id
}

output "rds_private_host" {
  value = module.rds.private_host
}

# RDS admin credential — loaded into Vault's DB engine at bootstrap so Vault can
# mint short-lived per-pod app users. Sensitive; not stored in CSMS/Git.
output "rds_admin_username" {
  value = module.rds.admin_username
}

output "rds_admin_password" {
  value     = module.rds.admin_password
  sensitive = true
}

output "redis_private_host" {
  value = module.dcs.private_host
}

# Redis password — written to Vault KV at bootstrap. Sensitive.
output "redis_password" {
  value     = module.dcs.redis_password
  sensitive = true
}

output "cce_cluster_name" {
  value = module.cce.cluster_name
}

output "elb_public_ip" {
  description = "Public entry point for the API (DNS points here)."
  value       = module.elb.public_ip
}

output "app_bucket" {
  value = module.obs.app_bucket
}

output "workload_agency_name" {
  value = module.iam.workload_agency_name
}
