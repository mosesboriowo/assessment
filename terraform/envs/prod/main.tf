# ---------------------------------------------------------------------------
# Production environment root. IDENTICAL module composition to staging — only
# the inputs differ (multi-AZ HA, two AZs, higher node ceiling). This is the
# "same modules, different variables" pattern (docs/architecture §4.14).
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
  # RESIDENCY TRADE-OFF: this DB holds customer/transaction data, so it is pinned
  # single-AZ in the Nigerian AZ. Cross-AZ HA is DISABLED because the region's
  # other AZs are in South Africa (docs/security-data-residency §B.0). The HA
  # trade-off is accepted for CBN compliance and mitigated with fast PITR +
  # on-prem DR. (If Huawei adds a 2nd Nigerian AZ, re-enable multi_az.)
  multi_az = false
  tags     = var.tags
}

module "dcs" {
  source = "../../modules/dcs"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.data_subnet_id
  security_group_id  = module.vpc.data_security_group_id
  availability_zones = var.availability_zones
  tags               = var.tags
}

module "obs" {
  source = "../../modules/obs"

  name_prefix = var.name_prefix
  kms_key_id  = module.rds.kms_key_id
  tags        = var.tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix    = var.name_prefix
  domain_name    = var.domain_name
  region_project = var.region
  tags           = var.tags
}

module "cce" {
  source = "../../modules/cce"

  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  app_subnet_id     = module.vpc.app_subnet_id
  availability_zone = var.availability_zone
  node_password     = var.node_password
  min_nodes         = 3
  max_nodes         = 8 # production headroom for traffic spikes
  tags              = var.tags
}

module "elb" {
  source = "../../modules/elb"

  name_prefix      = var.name_prefix
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  certificate_id   = var.certificate_id
  tags             = var.tags
}
