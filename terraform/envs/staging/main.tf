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

# --- Modules wired in subsequent iterations (kept here as the composition map):
# module "obs"  { ... }   # object storage + state bucket
# module "iam"  { ... }   # least-priv users + CCE workload agency
# module "rds"  { ... }   # MySQL, private-data subnet, KMS-encrypted
# module "dcs"  { ... }   # Redis
# module "cce"  { ... }   # managed Kubernetes cluster + node pool
# module "elb"  { ... }   # load balancer + TLS listener
