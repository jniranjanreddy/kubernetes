#!/bin/bash
#Step-1
#Source - https://vocon-it.com/2018/11/19/single-node-kubernetes-cluster-1-installing-minikube-on-centos/

cat << EOF > /etc/yum.repos.d/docker.repo
[docker-ce-edge]
name=Docker CE Edge - $basearch
baseurl=https://download.docker.com/linux/centos/7/$basearch/edge
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

yum install -y docker-ce   && sudo systemctl start docker   && sudo systemctl status docker   && sudo systemctl enable docker
docker ps
docker search hello


#Step-2
KUBE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl   && chmod +x kubectl   && mv -f kubectl /usr/local/bin/   && kubectl version
  
#Installing Minikube  
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64    && install minikube-linux-amd64 /usr/local/bin/minikube   && minikube version


yum install -y conntrack

#Initializing minikube in a VM, which is running in VirtualBox
minikube start --vm-driver=none
chown -R $USER $HOME/.kube $HOME/.minikube

#systemctl stop firewalld
#IF codednsfailes try below commands
#systemctl stop kubelet
#systemctl stop docker
#iptables --flush
#iptables -tnat --flush
systemctl enable kubelet 
systemctl start kubelet
systemctl enable docker
systemctl start docker

yum install -y wget
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
chmod +x kubectx kubens
sudo mv kubens kubectx /usr/local/bin

# Enable Ingress
minikube addons enable ingress

# Enable metric Server
minikube addons enable metrics-server
