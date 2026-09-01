output "loadbalancer_id" {
  value = huaweicloud_elb_loadbalancer.this.id
}

output "public_ip" {
  value = huaweicloud_elb_loadbalancer.this.ipv4_address
}
