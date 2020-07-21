# build instances on Openstack for a Kubernetes cluster
locals {
  worker_count = 38
  image_name = "GOLD Ubuntu 18.04 LTS"
  key_pair = "k8s-nodes"
  key_pair_location = "~/.ssh"
  ssh_security_group = "SSH and ICMP"
}

provider "openstack" {}

resource "openstack_networking_secgroup_v2" "instance_comms" {
  name = "k8s-comms"
  description = "Security group for allowing TCP communication for Kubernetes"
  delete_default_rules = true
}

# Allow tcp on port 6443 for IPv4 within security group
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_6443_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 6443
  port_range_max = 6443
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

# Allow tcp on port 6443 for IPv6 within security group
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_6443_ipv6" {
  direction = "ingress"
  ethertype = "IPv6"
  protocol  = "tcp"
  port_range_min = 6443
  port_range_max = 6443
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

resource "openstack_compute_instance_v2" "master_instance" {
  count = 1 
  name = "k8s-master-${count.index+1}"
  image_name = local.image_name
  flavor_name = "${local.worker_count < 11 ? "m1.large" : "m1.xlarge"}"

  key_pair = local.key_pair
  security_groups = [ local.ssh_security_group, openstack_networking_secgroup_v2.instance_comms.name ]

  network {
    name = "dualStack"
  }
}

resource "openstack_compute_instance_v2" "worker_instance" {
  count = local.worker_count
  name = "k8s-worker-${count.index+1}"
  image_name = local.image_name
  flavor_name = "m1.small"

  key_pair = local.key_pair
  security_groups = [ local.ssh_security_group, openstack_networking_secgroup_v2.instance_comms.name ]

  network {
    name = "dualStack"
  }
}

resource "local_file" "ansible_inventory" {
  content = "[master]\n${openstack_compute_instance_v2.master_instance[0].name} ansible_host=${openstack_compute_instance_v2.master_instance[0].access_ip_v4}\n\n[workers]\n${join("\n",
             formatlist(
               "%s ansible_host=%s",
               openstack_compute_instance_v2.worker_instance.*.name,
               openstack_compute_instance_v2.worker_instance.*.access_ip_v4
             ))}\n\n[all:vars]\nansible_python_interpreter=/usr/bin/python3\nansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\nansible_ssh_private_key_file=${local.key_pair_location}/${local.key_pair}\nansible_user=ubuntu"

  file_permission = "0600"
  filename = "ansible_inventory"
}
