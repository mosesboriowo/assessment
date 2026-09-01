# Environment-specific values for production. No secrets here.
region            = "af-south-1" # Southern-Africa region (Johannesburg); Nigerian AZ lives within it
name_prefix       = "cor-prod"
vpc_cidr          = "10.30.0.0/16"
availability_zone = ""
# RESIDENCY: only the Nigerian AZ may host residency-bound data. Cross-AZ HA is
# NOT used because the region's other AZs are in South Africa (see residency doc
# §B.0). Confirm the Nigerian AZ code in-console and use ONLY it here.
availability_zones = ["<nigerian-az-code>"] # single Nigerian AZ — verify code
domain_name        = "REPLACE_WITH_HUAWEI_ACCOUNT_NAME"

tags = {
  project     = "cashonrails-assessment"
  environment = "production"
  owner       = "moses-boriowo"
  residency   = "nigeria"
}
# node_password provided via TF_VAR_node_password in CI — never committed.
