#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.56.10"
REGISTRY_PORT="5000"
K3S_REGISTRIES_FILE="/etc/rancher/k3s/registries.yaml"
TOKEN_FILE="/vagrant/shared/node-token"

echo "[worker] Waiting for node-token from master..."
for i in {1..60}; do
  if [[ -s "${TOKEN_FILE}" ]]; then
    break
  fi
  echo "  ... token not found yet, retrying ($i/60)"
  sleep 5
done

if [[ ! -s "${TOKEN_FILE}" ]]; then
  echo "ERROR: node-token not found at ${TOKEN_FILE}"
  exit 1
fi

echo "[worker] Configure containerd mirrors to use master registry proxy..."
mkdir -p /etc/rancher/k3s
cat > "${K3S_REGISTRIES_FILE}" <<EOF
mirrors:
  docker.io:
    endpoint:
      - "http://rancher-master:${REGISTRY_PORT}"
      - "https://registry-1.docker.io"
configs:
  rancher-master:${REGISTRY_PORT}:
    tls:
      insecure_skip_verify: true
EOF

echo "[worker] Install K3s agent and join cluster..."
export K3S_URL="https://${MASTER_IP}:6443"
export K3S_TOKEN="$(cat ${TOKEN_FILE})"
curl -sfL https://get.k3s.io | K3S_URL="${K3S_URL}" K3S_TOKEN="${K3S_TOKEN}" sh -s - agent

echo "[worker] Done. Node should join automatically."
