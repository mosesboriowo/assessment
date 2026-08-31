output "vpc_id" {
  value = huaweicloud_vpc.this.id
}

output "public_subnet_id" {
  value = huaweicloud_vpc_subnet.public.id
}

output "app_subnet_id" {
  value = huaweicloud_vpc_subnet.app.id
}

output "data_subnet_id" {
  value = huaweicloud_vpc_subnet.data.id
}

output "elb_security_group_id" {
  value = huaweicloud_networking_secgroup.elb.id
}

output "app_security_group_id" {
  value = huaweicloud_networking_secgroup.app.id
}

output "data_security_group_id" {
  value = huaweicloud_networking_secgroup.data.id
}
