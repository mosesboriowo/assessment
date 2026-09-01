# Environment-specific values for production. No secrets here.
region             = "af-north-1" # ASSUMPTION: Nigeria region code — confirm in Huawei console
name_prefix        = "cor-prod"
vpc_cidr           = "10.30.0.0/16"
availability_zone  = ""
availability_zones = ["af-north-1a", "af-north-1b"] # two AZs → multi-AZ HA for RDS/DCS/nodes
domain_name        = "REPLACE_WITH_HUAWEI_ACCOUNT_NAME"

tags = {
  project     = "cashonrails-assessment"
  environment = "production"
  owner       = "moses-boriowo"
  residency   = "nigeria"
}
# node_password provided via TF_VAR_node_password in CI — never committed.
