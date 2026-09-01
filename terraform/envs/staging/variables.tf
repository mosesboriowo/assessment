variable "region" {
  description = "Huawei Cloud region hosting this environment. Pinned to the Nigerian location for residency."
  type        = string
}

variable "name_prefix" {
  description = "Naming prefix for this environment's resources."
  type        = string
  default     = "cor-staging"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zone" {
  description = "Primary AZ for the VPC subnets. Empty lets Huawei choose."
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "AZ list for RDS/DCS. Residency-bound data uses ONLY the Nigerian AZ within af-south-1 (single-AZ; see residency doc §B.0). Must be set in tfvars."
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Huawei account (domain) name the workload agency is delegated to."
  type        = string
}

variable "node_password" {
  description = "CCE node OS password. Provided via TF_VAR_node_password in CI — never committed."
  type        = string
  sensitive   = true
}

variable "certificate_id" {
  description = "ELB server certificate id (SCM). Empty if cert-manager terminates on ingress."
  type        = string
  default     = ""
}

variable "tags" {
  type = map(string)
  default = {
    project     = "cashonrails-assessment"
    environment = "staging"
    owner       = "moses-boriowo"
    residency   = "nigeria"
  }
}
