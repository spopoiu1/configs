#!/bin/bash

# install docker:

apt-get update
apt-get install -qy docker.io

# configure kubernetes apt repo:

apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update

# install kubernetes:

apt-get install -y kubelet kubeadm kubernetes-cni

# disable swap if exists (check: cat /proc/swaps)

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# initiate kubeadm (replace --apiserver-advertise-address with the IP of your host):

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(ifconfig eth0 | grep 'inet addr:' | cut -d ':' -f2 | cut -d ' ' -f1)

# configure unprivileged user:

useradd packet -G sudo -m -s /bin/bash
echo "packet:NEWPASSWORD" | chpasswd
su packet 


