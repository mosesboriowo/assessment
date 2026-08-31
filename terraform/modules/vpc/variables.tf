variable "name_prefix" {
  description = "Prefix applied to all network resource names (e.g. cor-staging)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

# Three-tier segmentation: public (ingress/NAT only), private-app (workloads),
# private-data (RDS/DCS — no internet route). Keeping these as separate variables
# keeps the module reusable across environments with different address space.
variable "public_subnet_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "app_subnet_cidr" {
  type    = string
  default = "10.20.10.0/24"
}

variable "data_subnet_cidr" {
  type    = string
  default = "10.20.20.0/24"
}

variable "availability_zone" {
  description = "AZ for subnets. Left empty lets Huawei choose; set explicitly for multi-AZ HA."
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "DNS resolvers for subnets."
  type        = list(string)
  default     = ["100.125.1.250", "100.125.129.250"] # Huawei internal resolvers
}

variable "nat_bandwidth_mbit" {
  description = "Egress bandwidth (Mbit/s) for the shared NAT EIP. Small on purpose for a cost-conscious assessment."
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags applied to taggable resources (used for cost allocation and residency audit)."
  type        = map(string)
  default     = {}
}
