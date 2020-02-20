kubernetes-playbooks
=============

Ansible playbooks that creates a Kubernetes 1.17 cluster on a cluster of Ubuntu 18.04 LTS servers.

## Prerequisites
* Ansible and Python3 installed on the local machine (`# yum install ansible`).
* SSH access to the servers from the local machine with SSH key pairs. Easiest method is to create/modify the `~.ssh/config` file on the local machine with the servers' login details.
* The servers will need to be in the `~/.ssh/known_hosts` file on the local machine (justlogging into them using SSH).
* TCP traffic on port 6443 must be permitted between the servers.

## Create a hosts file
 `$ cp hosts.example hosts`

Add the IP address to the master and workers in the `hosts` file using a text editor.

## Create a non-root user on all servers
*Skip this step if such a non-root user with sudo privileges named `ubuntu` was added on each server during server provisioning.*

 `$ ansible-playbook -i hosts playbooks/initial.yml`

## Install Kubernetes dependencies on all servers
 `$ ansible-playbook -i hosts playbooks/kube-dependencies.yml`

## Initialize the master node
 `$ ansible-playbook -i hosts playbooks/master.yml`

`ssh` onto the master and run `$ kubectl get nodes` to verify the master node get status `Ready`.

## Add the worker nodes
 `$ ansible-playbook -i hosts playbooks/workers.yml`

Run `$ kubectl get nodes` once more on the master node to verify the worker nodes got added.

## Credits
Based on bsder's Digital Ocean tutorial «[How To Create a Kubernetes 1.11 Cluster Using Kubeadm on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-1-11-cluster-using-kubeadm-on-ubuntu-18-04)».

## License
See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
