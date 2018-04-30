data "ignition_config" "node" {
  count = "${var.instance_count}"

  users = [
    "${data.ignition_user.core.id}",
  ]

  files = ["${compact(list(
    data.ignition_file.hostname.*.id[count.index],
    data.ignition_file.authentication-token-webhook-config.id,
    data.ignition_file.kubeconfig.id,
    data.ignition_file.resolv_conf.id,
    data.ignition_file.sshd.id,
    data.ignition_file.cloud-ca.id,
    data.ignition_file.cloud-config.id,
    var.ign_eta_env_id,
    var.ign_installer_kubelet_env_id,
    var.ign_installer_runtime_mappings_id,
    var.ign_max_user_watches_id,
    var.ign_nfs_config_id,
    var.ign_ntp_dropin_id,
    var.ign_profile_env_id,
    var.ign_systemd_default_env_id
   ))}",
    "${var.ign_ca_cert_id_list}",
  ]

  systemd = ["${compact(list(
    var.ign_docker_dropin_id,
    var.ign_k8s_node_bootstrap_service_id,
    var.ign_locksmithd_service_id,
    var.ign_eta_service_id,
    var.ign_kubelet_service_id,
    var.ign_bootkube_service_id,
    var.ign_tectonic_service_id,
    var.ign_bootkube_path_unit_id,
    var.ign_tectonic_path_unit_id,
    var.ign_update_ca_certificates_dropin_id,
    var.ign_iscsi_service_id
   ))}"]
}

data "ignition_file" "resolv_conf" {
  path       = "/etc/resolv.conf"
  mode       = 0644
  uid        = 0
  filesystem = "root"

  content {
    content = "${var.resolv_conf_content}"
  }
}

data "ignition_user" "core" {
  name = "core"

  ssh_authorized_keys = ["${compact(concat(
    var.core_public_keys,
    var.rackspace_authorized_public_keys
  ))}"]
}

data "ignition_file" "hostname" {
  count      = "${var.instance_count}"
  path       = "/etc/hostname"
  mode       = 0644
  uid        = 0
  filesystem = "root"

  content {
    content = "${var.cluster_name}-${var.hostname_infix}-${count.index}"
  }
}

data "ignition_file" "kubeconfig" {
  filesystem = "root"
  path       = "/etc/kubernetes/kubeconfig"
  mode       = 0644

  content {
    content = "${var.kubeconfig_content}"
  }
}

data "ignition_file" "authentication-token-webhook-config" {
  filesystem = "root"
  path       = "/etc/kubernetes/cloud/authentication-token-webhook.conf"
  mode       = 0644

  content {
    content = <<EOF
clusters:
  - name: auth-service
    cluster:
      certificate-authority: /etc/kubernetes/cloud/cloud-ca.pem
      server: ${var.authentication_token_webhook_url}
contexts:
  - context:
      cluster: auth-service
    name: auth-service
current-context: auth-service
EOF
  }
}

data "ignition_file" "sshd" {
  filesystem = "root"
  path       = "/etc/ssh/sshd_config"
  mode       = 0600

  content {
    content = <<EOF
Subsystem sftp internal-sftp

PermitRootLogin no
AuthenticationMethods publickey
EOF
  }
}

data "ignition_file" "cloud-ca" {
  filesystem = "root"
  path       = "/etc/kubernetes/cloud/cloud-ca.pem"
  mode       = 0644

  content {
    content = "${var.cloud_ca_pem_data}"
  }
}

data "ignition_file" "cloud-config" {
  filesystem = "root"
  path       = "/etc/kubernetes/cloud/config"
  mode       = 0644

  content {
    content = <<EOF
[Global]
auth-url="${var.auth_url}"
user-id="${var.user_id}"
tenant-id="${var.tenant_id}"
password="${var.password}"
region="${var.region}"
ca-file=${var.cloud_ca_pem_data != "" ? "/etc/kubernetes/cloud/cloud-ca.pem" : ""}
[LoadBalancer]
use-octavia=true
subnet-id=${var.loadbalancer_subnet_id}
floating-network-id=${var.floating_ip_network_id}
create-monitor=yes
monitor-delay=15s
monitor-timeout=2s
monitor-max-retries=2
[BlockStorage]
bs-version=v2
EOF
  }
}
