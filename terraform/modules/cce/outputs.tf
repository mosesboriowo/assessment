output "cluster_id" {
  value = huaweicloud_cce_cluster.this.id
}

output "cluster_name" {
  value = huaweicloud_cce_cluster.this.name
}

output "node_pool_id" {
  value = huaweicloud_cce_node_pool.default.id
}
