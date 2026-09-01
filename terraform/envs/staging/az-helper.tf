# ---------------------------------------------------------------------------
# HELPER — discover the availability zones in af-south-1 so you can identify the
# Nigerian AZ code and set it in `availability_zones`.
#
# After `terraform init` (with HW creds in the environment), run either:
#     terraform plan
#     # or:
#     terraform console
#     > data.huaweicloud_availability_zones.this.names
#
# The list gives AZ codes; cross-reference the console / Huawei docs to see which
# code is physically in Nigeria (region-scoped services like OBS may still sit in
# Johannesburg — see docs/security-data-residency §B.0/§B.4).
# ---------------------------------------------------------------------------
data "huaweicloud_availability_zones" "this" {}

output "available_zones_in_region" {
  description = "All AZ codes in af-south-1 — pick the Nigerian one for availability_zones."
  value       = data.huaweicloud_availability_zones.this.names
}
