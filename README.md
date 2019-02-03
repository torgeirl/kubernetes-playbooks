kubernetes-playbooks
=============

Ansible playbooks that creates a Kubernetes 1.12 cluster on your Ubuntu 18.04 servers.

## Prerequisites
* Ansible installed on your local machine (`# yum install ansible`).
* SSH access to your servers from your local maschine with SSH key pairs. Easiest metode is to create/modify your `~/.ssh/config` file with their login details.
* The servers will need to be in the `~/.ssh/known_hosts` file on your local machine (just SSH into each server manually).
* TCP trafic on port 6443 needs to be allowed between the servers.

## Create a hosts file
 `$ cp hosts.example hosts`

Add the IP address to the master and workers in your `hosts` file using your favorite text editor.

## Create a non-root user on all servers
*Skip if you already have a non-root user with sudo privileges named `ubuntu` on each server.*

 `$ ansible-playbook -i hosts playbooks/initial.yml`

## Install Kubernetes dependencies on all servers
 `$ ansible-playbook -i hosts playbooks/kube-dependencies.yml`

## Initialize your master node
 `$ ansible-playbook -i hosts playbooks/master.yml`

`ssh` onto the master and run `$ kubectl get nodes` to verify the master node get status `Ready`.

## Add your worker nodes
 `$ ansible-playbook -i hosts playbooks/workers.yml`

Run `$ kubectl get nodes` once more on the master node to verify the worker nodes got added.

## Credits
Based on bsder's Digital Ocean tutorial «[How To Create a Kubernetes 1.11 Cluster Using Kubeadm on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-kubernetes-1-11-cluster-using-kubeadm-on-ubuntu-18-04)».

## License
See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
