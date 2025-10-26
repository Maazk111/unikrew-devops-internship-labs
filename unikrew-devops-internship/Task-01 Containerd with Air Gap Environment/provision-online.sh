#!/bin/bash
set -e

echo "=============================="
echo "🌐 Setting up Containerd (Online Node)"
echo "=============================="

# 1️⃣ Install dependencies
sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 2️⃣ Add Docker repo (for containerd)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y containerd.io

# 3️⃣ Configure and enable containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd

echo "✅ Containerd running on Online Node"
sudo ctr version

# 4️⃣ Download .deb package for offline install
echo "📦 Downloading containerd .deb for offline node..."
mkdir -p /vagrant/shared/debs
cd /vagrant/shared/debs

# ensure apt can write here
sudo chown _apt:root /vagrant/shared/debs
apt download containerd.io

echo "✅ containerd .deb saved in /vagrant/shared/debs/"
ls -lh /vagrant/shared/debs/

echo "=============================="
echo "✅ Online Node Setup Complete"
echo "=============================="