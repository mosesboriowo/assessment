# Environment-specific values for staging. No secrets here — credentials come
# from the environment / CI.
region             = "af-south-1" # Southern-Africa region (Johannesburg); Nigerian AZ lives within it
name_prefix        = "cor-staging"
vpc_cidr           = "10.20.0.0/16"
availability_zone  = ""                     # VPC subnets — Huawei chooses
availability_zones = ["<nigerian-az-code>"] # the Nigerian AZ within af-south-1 — enumerate + confirm (see README)
domain_name        = "REPLACE_WITH_HUAWEI_ACCOUNT_NAME"
# node_password is NOT set here — provide via: export TF_VAR_node_password=... (from CSMS/CI)
