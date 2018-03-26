resource "openstack_dns_recordset_v2" "etcd_a_nodes" {
  count   = "${var.self_hosted_etcd != "" ? 0 : var.etcd_count}"
  type    = "A"
  ttl     = "60"
  zone_id = "${data.openstack_dns_zone_v2.tectonic.id}"
  name    = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}."
  records = ["${var.etcd_ip_addresses[count.index]}"]
}
