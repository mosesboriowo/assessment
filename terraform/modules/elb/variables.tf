variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_id" {
  description = "Public subnet for the internet-facing load balancer."
  type        = string
}
variable "certificate_id" {
  description = "Server certificate id (SCM). Empty in staging if using cert-manager on ingress."
  type        = string
  default     = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
