#!/bin/bash

set -e

echo "🚀 Installing Kubernetes Control Plane"

# -----------------------------
# Disable swap (MANDATORY)
# -----------------------------
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# -----------------------------
# Load kernel modules
# -----------------------------
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# -----------------------------
# Sysctl settings
# -----------------------------
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# -----------------------------
# Install containerd
# -----------------------------
apt-get update
apt-get install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# -----------------------------
# Install Kubernetes packages
# -----------------------------
apt-get update
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# -----------------------------
# Initialize Kubernetes
# -----------------------------
NODE_IP=$(hostname -I | awk '{print $1}')

kubeadm init \
  --apiserver-advertise-address=${NODE_IP} \
  --pod-network-cidr=192.168.0.0/16

# -----------------------------
# Configure kubectl for user
# -----------------------------
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# -----------------------------
# Install Calico CNI
# -----------------------------
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "✅ Control Plane setup complete!"
echo "👉 Save the kubeadm join command shown above."
