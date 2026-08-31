# ---------------------------------------------------------------------------
# Staging environment root. Composes reusable modules; environment-specific
# values come from terraform.tfvars. Production is an identical composition
# with different inputs (multi-AZ, larger sizing) — the "same modules,
# different variables" pattern (docs/architecture §4.14).
# ---------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name_prefix       = var.name_prefix
  vpc_cidr          = var.vpc_cidr
  availability_zone = var.availability_zone
  tags              = var.tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.data_subnet_id
  security_group_id  = module.vpc.data_security_group_id
  availability_zones = var.availability_zones
  multi_az           = false # staging runs single-AZ to save cost; prod = true
  tags               = var.tags
}

module "dcs" {
  source = "../../modules/dcs"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.data_subnet_id
  security_group_id  = module.vpc.data_security_group_id
  availability_zones = var.availability_zones
  kms_key_id         = module.rds.kms_key_id # reuse the DB KMS key for the secret
  tags               = var.tags
}

# --- Modules wired in subsequent iterations (composition map):
# module "obs"  { ... }   # object storage + state bucket
# module "iam"  { ... }   # least-priv users + CCE workload agency
# module "cce"  { ... }   # managed Kubernetes cluster + node pool
# module "elb"  { ... }   # load balancer + TLS listener
