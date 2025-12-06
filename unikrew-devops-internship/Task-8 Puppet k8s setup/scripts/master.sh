#!/bin/bash
set -e

echo "[1/10] Updating system..."
apt-get update -y

echo "[2/10] Installing containerd, kubeadm, kubelet, kubectl..."
apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release

# Fix: create directory for GPG keyrings
mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y containerd kubelet kubeadm kubectl
systemctl enable containerd kubelet

echo "[3/10] Configuring containerd..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

echo "[4/10] Enabling IP forwarding..."
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

echo "[5/10] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[6/10] Initializing Kubernetes control-plane..."
kubeadm init \
  --apiserver-advertise-address=192.168.56.10 \
  --pod-network-cidr=192.168.0.0/16 \
  --ignore-preflight-errors=swap

echo "[7/10] Setting up kubeconfig..."
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Persist kubeconfig for root & vagrant
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "[8/10] Waiting for Kubernetes API to become ready..."
until kubectl get nodes >/dev/null 2>&1; do
  echo "⏳ Waiting for API server..."
  sleep 5
done

echo "[9/10] Installing Calico CNI..."
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml"

echo "[10/10] Generating join command..."
kubeadm token create --print-join-command > /shared/join.sh

echo "✅ Master node setup complete!"