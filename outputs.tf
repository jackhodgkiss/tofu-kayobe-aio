output "instance_details" {
  value = format("VM Name: %s, Flavor: %s, VCPUs: %s, RAM: %d MB, Disk: %.1f GB"
    , openstack_compute_instance_v2.instance.name
    , data.openstack_compute_flavor_v2.instance_flavor.name
    , data.openstack_compute_flavor_v2.instance_flavor.vcpus
    , data.openstack_compute_flavor_v2.instance_flavor.ram
    , openstack_compute_instance_v2.instance.block_device[0].volume_size
  )
}

output "instance_ssh_instructions" {
  value = format("ssh cloud-user@%s", local.formatted_instance_name)
}

output "instance_sshuttle_instructions" {
  value = format("sshuttle -r cloud-user@%s 192.168.33.0/24", local.formatted_instance_name)
}

locals {
  formatted_instance_name = var.dns_zone_name != null ? substr(openstack_dns_recordset_v2.lab_dns[0].name, 0, length(openstack_dns_recordset_v2.lab_dns[0].name) - 1) : openstack_compute_instance_v2.instance.network[0].fixed_ip_v4
}

resource "local_file" "automated_setup" {
  content = templatefile(
    "${path.module}/templates/automated_setup.tpl",
    {
      kayobe_branch = var.kayobe_branch
      kayobe_config_branch = var.kayobe_config_branch
      use_lvm = var.use_lvm
      allow_config_edit = var.allow_config_edit
      run_tempest = var.run_tempest
    }
  )
  filename = "automated-setup.sh"
  file_permission = "0744"
}
