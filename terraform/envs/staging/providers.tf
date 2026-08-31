# Credentials are NOT set here. They are read from the environment
# (HW_ACCESS_KEY / HW_SECRET_KEY) or a CI OIDC/agency — never committed.
# See docs/security-data-residency for the credential-handling model.
provider "huaweicloud" {
  region = var.region
}
