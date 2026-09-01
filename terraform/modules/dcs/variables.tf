variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" {
  description = "Private-data subnet id."
  type        = string
}
variable "security_group_id" {
  description = "Data-tier SG permitting 6379 only from the app tier."
  type        = string
}
variable "availability_zones" {
  type = list(string)
}
variable "capacity" {
  description = "Redis capacity in GB."
  type        = number
  default     = 2
}
variable "flavor" {
  description = "DCS flavor/spec code. Verify in Huawei console. HA flavor in prod."
  type        = string
  default     = "redis.ha.xu1.large.r2.2"
}
variable "engine_version" {
  type    = string
  default = "6.0"
}
variable "tags" {
  type    = map(string)
  default = {}
}
