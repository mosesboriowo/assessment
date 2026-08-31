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
