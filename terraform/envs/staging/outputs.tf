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

output "rds_app_secret_name" {
  description = "CSMS secret the app reads for DB credentials."
  value       = module.rds.app_credentials_secret_name
}

output "redis_private_host" {
  value = module.dcs.private_host
}

output "redis_app_secret_name" {
  value = module.dcs.app_credentials_secret_name
}
