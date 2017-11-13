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
tar xf helm-v2.7.0-linux-amd64.tar.gz

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
mkdir $HOME/work
sudo cp -r /usr/local/go $HOME/work
export GOPATH=$HOME/work
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
mkdir -p $(go env GOPATH)/src/github.com/Azure 
git clone https://github.com/Azure/brigade $(go env GOPATH)/src/github.com/Azure/brigade
pushd $(go env GOPATH)/src/github.com/Azure/brigade
apt install -y npm
apt install -y fakeroot
fakeroot make bootstrap build
cp /root/work/src/github.com/Azure/brigade/bin/* /usr/bin

# install brigade:
# clone the repo:

git clone https://github.com/Azure/brigade.git
cd ./brigade

# install brigade:

kubectl create clusterrolebinding --user system:serviceaccount:kube-system:default kube-system-cluster-admin --clusterrole cluster-admin
helm install --name brigade ./chart/brigade

# create a test project:

helm inspect values ./brigade-project > myvalues.yaml
# edit myvalues.yaml
helm install --name my-project ./brigade-project -f myvalues.yaml
cat << EOF > brigade.js
const { events } = require('brigadier')

events.on("exec", (brigadeEvent, project) => {
   console.log("Hello world!")
 })
EOF

# run the test project:

./brig run -f brigade.js my-project