#!/bin/bash
#this script should be run as a non root user
# install docker:

sudo apt-get update
sudo apt-get install -y docker.io

# configure kubernetes apt repo:

sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/kubernetes.list
sudo chmod 777 /etc/apt/sources.list.d/kubernetes.list
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# install kubernetes:

sudo apt-get install -y kubelet kubeadm kubernetes-cni

# disable swap if exists (check: cat /proc/swaps)

swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# initiate kubeadm (replace --apiserver-advertise-address with the IP of your host):

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(ifconfig eth0 | grep 'inet addr:' | cut -d ':' -f2 | cut -d ' ' -f1)

# configure environment variables:

sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
echo "export KUBECONFIG=$HOME/admin.conf" | tee -a ~/.bashrc

# configure pod network:

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

# taint master (so that containers can run on master):

kubectl taint nodes --all node-role.kubernetes.io/master-

# install helm:
# download desired version from https://github.com/kubernetes/helm/releases:

wget https://storage.googleapis.com/kubernetes-helm/helm-v2.7.0-linux-amd64.tar.gz
tar -zxf helm-v2.7.0-linux-amd64.tar.gz

# copy binaries into PATH:

sudo cp linux-amd64/helm /usr/bin/

# initiate helm:

helm init

# create the binaries for brigade

sudo apt-get update
sudo apt-get -y upgrade
wget https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
tar -xvf go1.9.2.linux-amd64.tar.gz
sudo mv go /usr/local
export GOROOT=/usr/local/go
echo "export GOROOT=/usr/local/go" | tee -a ~/.bashrc
mkdir $HOME/work
sudo cp -r /usr/local/go $HOME/work
export GOPATH=$HOME/work
echo "export GOPATH=$HOME/work" | tee -a ~/.bashrc
export PATH=$GOPATH/bin:$GOPATH/go/bin:$GOROOT/bin:$PATH
mkdir -p $(go env GOPATH)/src/github.com/Azure 
git clone https://github.com/Azure/brigade $(go env GOPATH)/src/github.com/Azure/brigade
pushd $(go env GOPATH)/src/github.com/Azure/brigade
sudo apt install -y npm
sudo apt install -y fakeroot
last_error=$?
if [[ $last_error == "1" ]];then
fakeroot make bootstrap build
fi
sudo cp $HOME/work/src/github.com/Azure/brigade/bin/* /usr/bin
popd 
# install brigade:
# clone the repo:

git clone https://github.com/Azure/brigade.git
pushd ./brigade

# install brigade:

kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:default:brigade-brigade-ctrl kube-system-cluster-admin1 --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:default:brigade-brigade-ctrl kube-system-cluster-admin11 --clusterrole cluster-admin
kubectl create clusterrolebinding --user system:serviceaccount:default:default kube-system-cluster-admin111 --clusterrole cluster-admin

helm install --name brigade ./chart/brigade
# create a test project:

helm inspect values ./chart/brigade-project > myvalues.yaml
# edit myvalues.yaml
helm install --name my-project ./chart/brigade-project -f myvalues.yaml
cat << EOF > brigade.js
const { events } = require('brigadier')

events.on("exec", (brigadeEvent, project) => {
   console.log("Hello world!")
 })
EOF
