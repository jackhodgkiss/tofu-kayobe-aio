locals {
  user_data = templatefile(
    "${path.module}/templates/user_data.tpl",
    {
      user_ssh_key = data.openstack_compute_keypair_v2.instance_keypair.public_key
    }
  )
}
