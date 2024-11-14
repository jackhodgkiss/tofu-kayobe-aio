data "openstack_images_image_v2" "instance_image" {
  name        = var.instance_image_name
  most_recent = true
}