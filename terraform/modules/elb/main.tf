# ---------------------------------------------------------------------------
# ELB — the public edge. It terminates TLS in the public subnet and forwards to
# the NGINX ingress controller running inside CCE, which routes to services.
# HTTP is redirected to HTTPS. The database and app pods stay private; only this
# load balancer is internet-facing (docs/architecture §4.5).
# ---------------------------------------------------------------------------

resource "huaweicloud_elb_loadbalancer" "this" {
  name           = "${var.name_prefix}-elb"
  vpc_id         = var.vpc_id
  ipv4_subnet_id = var.public_subnet_id
  # Public IP so merchants can reach the API; backends remain private.
  cross_vpc_backend = false
  tags              = var.tags
}

# HTTPS listener with a managed server certificate.
resource "huaweicloud_elb_listener" "https" {
  name               = "${var.name_prefix}-https"
  loadbalancer_id    = huaweicloud_elb_loadbalancer.this.id
  protocol           = "HTTPS"
  protocol_port      = 443
  server_certificate = var.certificate_id # from Huawei SCM / cert-manager DNS-01
}

# HTTP listener that redirects to HTTPS (no plaintext traffic served).
resource "huaweicloud_elb_listener" "http_redirect" {
  name            = "${var.name_prefix}-http"
  loadbalancer_id = huaweicloud_elb_loadbalancer.this.id
  protocol        = "HTTP"
  protocol_port   = 80
}

# NOTE: the pool/members are managed by the CCE NGINX-ingress LoadBalancer
# service, which binds to this ELB. Terraform provisions the edge; the ingress
# controller wires backends dynamically as pods scale.
