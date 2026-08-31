# ---------------------------------------------------------------------------
# VPC module — network foundation with three-tier segmentation.
#
# Design intent (see docs/architecture §4.4):
#   public       -> ELB + NAT gateway only (internet-facing edge)
#   private-app  -> CCE worker nodes / API pods (no public IP)
#   private-data -> RDS + DCS (no internet route at all)
#
# Segmentation is enforced with security groups (least privilege) + NAT for
# controlled egress. No workload subnet is directly internet-reachable.
# ---------------------------------------------------------------------------

resource "huaweicloud_vpc" "this" {
  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr
  tags = var.tags
}

# --- Subnets -----------------------------------------------------------------
resource "huaweicloud_vpc_subnet" "public" {
  name              = "${var.name_prefix}-public"
  vpc_id            = huaweicloud_vpc.this.id
  cidr              = var.public_subnet_cidr
  gateway_ip        = cidrhost(var.public_subnet_cidr, 1)
  availability_zone = var.availability_zone
  dns_list          = var.dns_servers
  tags              = var.tags
}

resource "huaweicloud_vpc_subnet" "app" {
  name              = "${var.name_prefix}-app"
  vpc_id            = huaweicloud_vpc.this.id
  cidr              = var.app_subnet_cidr
  gateway_ip        = cidrhost(var.app_subnet_cidr, 1)
  availability_zone = var.availability_zone
  dns_list          = var.dns_servers
  tags              = var.tags
}

resource "huaweicloud_vpc_subnet" "data" {
  name              = "${var.name_prefix}-data"
  vpc_id            = huaweicloud_vpc.this.id
  cidr              = var.data_subnet_cidr
  gateway_ip        = cidrhost(var.data_subnet_cidr, 1)
  availability_zone = var.availability_zone
  dns_list          = var.dns_servers
  tags              = var.tags
}

# --- Security groups (least privilege) --------------------------------------
# delete_default_rules = true so we start from deny-all and add only what we need.

resource "huaweicloud_networking_secgroup" "elb" {
  name                 = "${var.name_prefix}-elb-sg"
  delete_default_rules = true
}

resource "huaweicloud_networking_secgroup" "app" {
  name                 = "${var.name_prefix}-app-sg"
  delete_default_rules = true
}

resource "huaweicloud_networking_secgroup" "data" {
  name                 = "${var.name_prefix}-data-sg"
  delete_default_rules = true
}

# ELB: allow HTTPS from the internet (TLS terminates at the edge).
resource "huaweicloud_networking_secgroup_rule" "elb_https_in" {
  security_group_id = huaweicloud_networking_secgroup.elb.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
}

# App: allow the FrankenPHP port (8080) ONLY from the ELB security group.
resource "huaweicloud_networking_secgroup_rule" "app_from_elb" {
  security_group_id = huaweicloud_networking_secgroup.app.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_group_id   = huaweicloud_networking_secgroup.elb.id
}

# Data: allow MySQL (3306) and Redis (6379) ONLY from the app security group.
resource "huaweicloud_networking_secgroup_rule" "data_mysql_from_app" {
  security_group_id = huaweicloud_networking_secgroup.data.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = huaweicloud_networking_secgroup.app.id
}

resource "huaweicloud_networking_secgroup_rule" "data_redis_from_app" {
  security_group_id = huaweicloud_networking_secgroup.data.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6379
  port_range_max    = 6379
  remote_group_id   = huaweicloud_networking_secgroup.app.id
}

# Controlled egress for app + data (image pulls, migrations, patches) via NAT.
resource "huaweicloud_networking_secgroup_rule" "app_egress" {
  security_group_id = huaweicloud_networking_secgroup.app.id
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
}

# --- NAT gateway for private-subnet egress ----------------------------------
resource "huaweicloud_nat_gateway" "this" {
  name      = "${var.name_prefix}-nat"
  spec      = "1" # smallest spec — cost-conscious for the assessment
  vpc_id    = huaweicloud_vpc.this.id
  subnet_id = huaweicloud_vpc_subnet.public.id
}

resource "huaweicloud_vpc_eip" "nat" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name       = "${var.name_prefix}-nat-bw"
    size       = var.nat_bandwidth_mbit
    share_type = "PER"
  }
  tags = var.tags
}

resource "huaweicloud_nat_snat_rule" "app" {
  nat_gateway_id = huaweicloud_nat_gateway.this.id
  subnet_id      = huaweicloud_vpc_subnet.app.id
  floating_ip_id = huaweicloud_vpc_eip.nat.id
}
