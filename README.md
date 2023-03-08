kubernetes-playbooks
=============

Ansible playbooks that creates a Kubernetes 1.26 cluster of Openstack instances running Ubuntu 22.04 LTS.

## Prerequisites
* Ansible and Python3 installed on the local machine (`# yum install ansible`).
* An OpenStack security group for SSH and ICMP access named `SSH and ICMP`.
* [Terraform](https://www.terraform.io/downloads.html) and [OpenStack CLI tools](https://docs.nrec.no/api.html) installed on the local machine.

## Create a `keystone_rc` file
 `$ cp keystone_rc.sh.example keystone_rc.sh`

 `$ chmod 0600 keystone_rc.sh`

The `keystone_rc.sh` file will contain your API password so be careful with where you store it, and make sure it's private. Once it is, add your API password for OpenStack. You can also modify the worker count, network version, etc.

Then load the file to the shell environment on the local computer:

 `$ source keystone_rc.sh`

## Add a public key for the cluster to the API user
SSH key pairs are tied to users, and the dashboard and API user are technically different. The SSH public key therefore has to be [added to the API user](https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/keypair.html#keypair-create) explicitly:

 `$ openstack keypair create --public-key /path/to/keyfile.pub k8s-nodes`

## Build the cluster using Terraform
Change directory to `tf-project` and initialize Terraform:

 `$ cd tf-project`

 `$ terraform init`

Then verify, plan and apply with Terraform:

 `$ terraform validate`

 `$ terraform plan`

 `$ terraform apply`

Change directory back to the main directory:

 `$ cd ..`

## Create an inventory file for Ansible
After creating the cluster on OpenStack, Terraform created a `ansible_inventory` file in the `tf-project` directory. It contains the machine names and IP addresses for the cluster.

Alternatively, a `hosts` file can be created. Add the IP address to the master and workers in the `hosts` file using a text editor, and make sure each machine can be reached using SSH:

 `$ cp hosts.example hosts`

 `$ vim hosts`

## Install Kubernetes dependencies on all servers
 `$ ansible-playbook -i tf-project/ansible_inventory playbooks/kube-dependencies.yml`

## Initialize the master node
 `$ ansible-playbook -i tf-project/ansible_inventory playbooks/master.yml`

`ssh` onto the master and verify that the master node get status `Ready`:
```
$ ssh -i /path/to/ssh-key ubuntu@<master_ip>
ubuntu@k8s-master-1:~$ kubectl get nodes
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   63s   v1.26.2
```

## Add the worker nodes
 `$ ansible-playbook -i tf-project/ansible_inventory playbooks/workers.yml`

Run `kubectl get nodes` once more on the master node to verify the worker nodes got added.

## Change or destroy the cluster
Edit cluster settings in the `keystone_rc.sh` and source it again before re-running `terraform apply` to change the cluster, before re-running the playbooks to add new workers.

Destroy the cluster when done:

 `$ cd tf-project`

 `$ terraform destroy`

## Credits
Based on bsder's Digital Ocean tutorial «[How To Create a Kubernetes 1.11 Cluster Using Kubeadm on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-1-11-cluster-using-kubeadm-on-ubuntu-18-04)».

## License
See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
