terraform {
  required_version = ">= 1.6.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70" # pinned to a minor line for reproducible plans
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
