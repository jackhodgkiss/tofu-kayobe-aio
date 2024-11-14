resource "openstack_compute_instance_v2" "instance" {
  name            = "${random_shuffle.scientist.result[0]}-${random_id.random_uuid.hex}"
  flavor_id       = var.instance_flavor_id
  key_pair        = var.instance_keypair_name
  security_groups = var.instance_security_groups

  user_data = local.user_data

  block_device {
    boot_index            = 0
    delete_on_termination = true
    destination_type      = "volume"
    source_type           = "image"
    uuid                  = data.openstack_images_image_v2.instance_image.id
    volume_size           = var.instance_volume_size
  }

  network {
    name = var.instance_network_name
  }
}
