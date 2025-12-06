#!/bin/bash
set -e

echo "[1/7] Updating system..."
apt-get update -y

echo "[2/7] Installing containerd & Kubernetes components..."
apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y containerd kubelet kubeadm kubectl
systemctl enable containerd kubelet

echo "[3/7] Configuring containerd..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

echo "[4/7] Enabling IP forwarding..."
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

echo "[5/7] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[6/7] Waiting for join.sh from master..."
while [ ! -f /shared/join.sh ]; do
  echo "Waiting for master to generate join.sh..."
  sleep 4
done

echo "[7/7] Joining cluster..."
bash /shared/join.sh --ignore-preflight-errors=swap

echo "✅ Worker successfully joined the cluster!"