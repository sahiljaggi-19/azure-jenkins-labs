#!/bin/bash

set -e

echo "🚀 Installing Kubernetes Worker Node"

# -----------------------------
# Disable swap
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
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

echo "✅ Worker node prerequisites installed!"
echo "👉 Run the kubeadm join command from the control-plane node."
