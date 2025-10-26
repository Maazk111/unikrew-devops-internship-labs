#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.56.10"
WORKER1_IP="192.168.56.11"
WORKER2_IP="192.168.56.12"
KONG_IP="192.168.56.15"

echo "[common] 🔧 Updating apt and installing base packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl vim net-tools jq ca-certificates apt-transport-https nfs-common git ufw

echo "[common] 🔒 Disabling swap (required by Kubernetes)..."
swapoff -a || true
sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab || true

echo "[common] ⚙️ Kernel parameters for Kubernetes networking..."
cat >/etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF
modprobe br_netfilter
cat >/etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
sysctl --system

echo "[common] 🌐 Adding hosts entries for Rancher + Kong setup..."
grep -q "rancher-master" /etc/hosts || cat >>/etc/hosts <<EOF

${MASTER_IP}   rancher-master rancher.local
${WORKER1_IP}  worker1
${WORKER2_IP}  worker2
${KONG_IP}     kong-gateway kong.local
EOF

echo "[common] ✅ Base setup complete and network entries configured."

# Optional connectivity check (non-blocking)
( ping -c 1 rancher-master >/dev/null 2>&1 && echo "[common] 🟢 Rancher reachable" ) || echo "[common] ⚠️ Rancher not reachable yet"
( ping -c 1 kong-gateway >/dev/null 2>&1 && echo "[common] 🟢 Kong reachable" ) || echo "[common] ⚠️ Kong not reachable yet"