variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" {
  description = "Private-data subnet id — RDS is never placed in a public subnet."
  type        = string
}
variable "security_group_id" {
  description = "Data-tier SG that only permits 3306 from the app tier."
  type        = string
}
variable "availability_zones" {
  description = "One AZ for staging (cost); two for prod to enable HA (primary+standby)."
  type        = list(string)
}
variable "multi_az" {
  description = "Enable synchronous HA replica across AZs (prod)."
  type        = bool
  default     = false
}
variable "flavor" {
  description = "RDS flavor. Small in staging. Verify exact flavor code in the Huawei console."
  type        = string
  default     = "rds.mysql.n1.large.2"
}
variable "volume_size" {
  type    = number
  default = 40
}
variable "backup_keep_days" {
  description = "Automated backup retention (days). Drives PITR window."
  type        = number
  default     = 7
}
variable "db_name" {
  type    = string
  default = "cashonrails"
}
variable "kms_key_id" {
  description = "Existing KMS key for at-rest encryption; if empty a key is created."
  type        = string
  default     = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
