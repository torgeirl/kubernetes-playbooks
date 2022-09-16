# build instances on Openstack for a Kubernetes cluster
variable "K8S_WORKER_COUNT" {}
variable "K8S_WORKER_FLAVOR" {}
variable "K8S_IMAGE_NAME" {}
variable "K8S_NETWORK_NAME" {}
variable "K8S_KEY_PAIR" {}
variable "K8S_KEY_PAIR_LOCATION" {}
variable "K8S_SECURITY_GROUP" {}

terraform {
  required_version = ">= 0.13"
}

provider "openstack" {}

resource "openstack_networking_secgroup_v2" "instance_comms" {
  name = "k8s-comms"
  description = "Security group for allowing TCP communication for Kubernetes"
  delete_default_rules = true
}

# Allow tcp on port 2379-2380 for IPv4 within security group (etcd)
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_etcd_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 2379
  port_range_max = 2380
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

# Allow tcp on port 6443 for IPv4 within security group (API server)
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_6443_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 6443
  port_range_max = 6443
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

# Allow tcp on port 10250 for IPv4 within security group (Kubelet API)
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_10250_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 10250
  port_range_max = 10250
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

# Allow tcp on port 10257 for IPv4 within security group (kube-controller-manager)
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_10257_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 10257
  port_range_max = 10257
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

# Allow tcp on port 10259 for IPv4 within security group (kube-scheduler)
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_10259_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 10259
  port_range_max = 10259
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

# Allow tcp on port 30000-32767 for IPv4 within security group (NodePort Services†)
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_tcp_nodeport_ipv4" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "tcp"
  port_range_min = 30000
  port_range_max = 32767
  remote_group_id = openstack_networking_secgroup_v2.instance_comms.id
  security_group_id = openstack_networking_secgroup_v2.instance_comms.id
}

resource "openstack_compute_instance_v2" "master_instance" {
  count = 1 
  name = "k8s-master-${count.index+1}"
  image_name = var.K8S_IMAGE_NAME
  flavor_name = var.K8S_WORKER_COUNT < 11 ? "m1.large" : "m1.xlarge"

  key_pair = var.K8S_KEY_PAIR
  security_groups = [ var.K8S_SECURITY_GROUP, openstack_networking_secgroup_v2.instance_comms.name ]

  network {
    name = var.K8S_NETWORK_NAME
  }
}

resource "openstack_compute_instance_v2" "worker_instance" {
  count = var.K8S_WORKER_COUNT
  name = "k8s-worker-${count.index+1}"
  image_name = var.K8S_IMAGE_NAME

  flavor_name = var.K8S_WORKER_FLAVOR

  key_pair = var.K8S_KEY_PAIR
  security_groups = [ var.K8S_SECURITY_GROUP, openstack_networking_secgroup_v2.instance_comms.name ]

  network {
    name = var.K8S_NETWORK_NAME
  }
}

resource "local_file" "ansible_inventory" {
  content = "[master]\n${openstack_compute_instance_v2.master_instance[0].name} ansible_host=${openstack_compute_instance_v2.master_instance[0].access_ip_v4}\n\n[workers]\n${join("\n",
             formatlist(
               "%s ansible_host=%s",
               openstack_compute_instance_v2.worker_instance.*.name, openstack_compute_instance_v2.worker_instance.*.access_ip_v4
             ))}\n\n[all:vars]\nansible_python_interpreter=/usr/bin/python3\nansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\nansible_ssh_private_key_file=${var.K8S_KEY_PAIR_LOCATION}/${var.K8S_KEY_PAIR}\nansible_user=ubuntu"

  file_permission = "0600"
  filename = "ansible_inventory"
}
