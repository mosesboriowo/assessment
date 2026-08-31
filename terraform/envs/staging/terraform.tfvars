# Environment-specific values for staging. No secrets here — credentials come
# from the environment / CI. Region is the Nigerian location (verify code).
region             = "af-north-1" # ASSUMPTION: Nigeria region code — confirm in Huawei console
name_prefix        = "cor-staging"
vpc_cidr           = "10.20.0.0/16"
availability_zone  = ""              # VPC subnets — Huawei chooses
availability_zones = ["af-north-1a"] # ASSUMPTION: verify AZ code; single-AZ in staging
