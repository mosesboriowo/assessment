variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "app_subnet_id" {
  description = "Private app subnet for the cluster/nodes."
  type        = string
}
variable "availability_zone" {
  description = "Node AZ. Prod uses a multi-AZ node pool for HA."
  type        = string
}
variable "cluster_flavor" {
  description = "CCE control-plane flavor. HA flavor in prod. Verify code in console."
  type        = string
  default     = "cce.s1.small"
}
variable "node_flavor" {
  description = "Worker node ECS flavor."
  type        = string
  default     = "s6.large.2"
}
variable "min_nodes" {
  type    = number
  default = 2
}
variable "max_nodes" {
  type    = number
  default = 5
}
variable "expose_api_eip" {
  description = "Optional EIP for the K8s API. Prefer private + bastion in prod."
  type        = string
  default     = null
}
variable "node_password" {
  description = "Node OS password (from CSMS/CI env, never committed)."
  type        = string
  sensitive   = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
