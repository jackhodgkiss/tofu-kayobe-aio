data "openstack_dns_zone_v2" "zone" {
  count = var.dns_zone_name != null ? 1 : 0
  name  = var.dns_zone_name
}

resource "openstack_dns_recordset_v2" "lab_dns" {
  count      = var.dns_zone_name != null ? 1 : 0
  zone_id    = data.openstack_dns_zone_v2.zone[0].id
  name       = format("%s.%s", openstack_compute_instance_v2.instance.name, var.dns_zone_name)
  type       = "A"
  ttl        = 300
  records    = [openstack_compute_instance_v2.instance.network[0].fixed_ip_v4]
  depends_on = [openstack_compute_instance_v2.instance]
}