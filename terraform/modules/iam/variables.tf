variable "name_prefix" { type = string }
variable "domain_name" {
  description = "Huawei account (domain) name the agency is delegated to."
  type        = string
}
variable "region_project" {
  description = "Project name for the Nigerian region (scopes the agency roles)."
  type        = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
