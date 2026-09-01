variable "name_prefix" { type = string }
variable "kms_key_id" {
  description = "KMS key for bucket encryption (shared with RDS)."
  type        = string
}
variable "noncurrent_version_days" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}
