data "openstack_compute_flavor_v2" "instance_flavor" {
  flavor_id = var.instance_flavor_id
}