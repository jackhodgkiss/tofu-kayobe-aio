data "openstack_compute_keypair_v2" "instance_keypair" {
  name = var.instance_keypair_name
}