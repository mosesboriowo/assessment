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
  description = "Primary AZ. For production, pass a second AZ to the DB/CCE modules for multi-AZ HA."
  type        = string
  default     = ""
}

variable "tags" {
  type = map(string)
  default = {
    project     = "cashonrails-assessment"
    environment = "staging"
    owner       = "moses-boriowo"
    residency   = "nigeria" # used to audit that residency-bound resources are correctly located
  }
}
