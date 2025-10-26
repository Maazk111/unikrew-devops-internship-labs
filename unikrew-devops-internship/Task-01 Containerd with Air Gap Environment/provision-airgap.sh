#!/bin/bash
set -e

echo "=============================="
echo "✈️ Setting up Containerd (Air-Gapped Node)"
echo "=============================="

PKG_DIR="/vagrant/shared/debs"

# 1️⃣ Install containerd from shared folder
if [ -d "$PKG_DIR" ] && ls $PKG_DIR/containerd.io*.deb 1> /dev/null 2>&1; then
  echo "📦 Installing containerd from local .deb..."
  sudo dpkg -i $PKG_DIR/containerd.io*.deb || sudo apt-get install -f -y
else
  echo "❌ No containerd .deb found in $PKG_DIR"
  echo "Please ensure it was downloaded on the online node first."
  exit 1
fi

# 2️⃣ Configure and start containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd

echo "✅ Containerd installed and running on Air-Gap Node"
sudo ctr version

echo "=============================="
echo "✅ Air-Gapped Containerd Setup Complete"
echo "=============================="