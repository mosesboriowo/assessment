# ---------------------------------------------------------------------------
# CCE — Huawei's managed Kubernetes. Chosen over single VMs because the brief
# requires this to become a reusable platform for many services (Part 2); K8s
# gives rolling updates, probes, HPA and self-healing out of the box, and keeps
# workloads portable/cloud-agnostic. Cluster runs in the private app subnet;
# nodes span AZs in prod for HA.
# ---------------------------------------------------------------------------

resource "huaweicloud_cce_cluster" "this" {
  name                   = "${var.name_prefix}-cce"
  cluster_type           = "VirtualMachine"
  flavor_id              = var.cluster_flavor # e.g. cce.s1.small (staging) / HA flavor (prod)
  vpc_id                 = var.vpc_id
  subnet_id              = var.app_subnet_id # private app subnet
  container_network_type = "overlay_l2"
  authentication_mode    = "rbac"

  # Private cluster: no public API endpoint unless explicitly enabled for ops.
  eip = var.expose_api_eip
}

resource "huaweicloud_cce_node_pool" "default" {
  cluster_id         = huaweicloud_cce_cluster.this.id
  name               = "${var.name_prefix}-pool"
  flavor_id          = var.node_flavor
  availability_zone  = var.availability_zone
  initial_node_count = var.min_nodes
  password           = var.node_password

  # Cluster autoscaler: nodes scale with pending pods (pairs with pod-level HPA).
  scall_enable             = true
  min_node_count           = var.min_nodes
  max_node_count           = var.max_nodes
  scale_down_cooldown_time = 10

  root_volume {
    size       = 50
    volumetype = "SSD"
  }
  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = var.tags
}
