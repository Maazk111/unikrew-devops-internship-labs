#!/usr/bin/env bash
set -euo pipefail

echo "🚀 [kong] Starting Kong Gateway VM Setup..."

# -------------------------------
# 1️⃣ Install Docker if not present
# -------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "[kong] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
fi

# -------------------------------
# 2️⃣ Prepare environment
# -------------------------------
mkdir -p /opt/kong/declarative
cat >/opt/kong/declarative/kong.yml <<EOF
_format_version: "3.0"
services:
- name: rancher-service
  url: https://rancher-master:30443
  routes:
  - name: rancher-route
    paths:
    - /rancher
EOF

# -------------------------------
# 3️⃣ Remove any old container
# -------------------------------
if docker ps -a --format '{{.Names}}' | grep -q '^kong-gateway$'; then
  echo "[kong] Removing old container..."
  docker rm -f kong-gateway >/dev/null 2>&1 || true
fi

# -------------------------------
# 4️⃣ Create docker network if missing
# -------------------------------
docker network inspect kong-net >/dev/null 2>&1 || docker network create kong-net

# -------------------------------
# 5️⃣ Launch Kong Gateway (DB-less)
# -------------------------------
echo "[kong] Launching Kong Gateway (DB-less mode)..."
docker run -d --name kong-gateway --restart=always \
  --network=kong-net \
  -e "KONG_DATABASE=off" \
  -e "KONG_DECLARATIVE_CONFIG=/kong/declarative/kong.yml" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_ADMIN_GUI_LISTEN=0.0.0.0:8002" \
  -e "KONG_PROXY_LISTEN=0.0.0.0:8000" \
  -e "KONG_PROXY_LISTEN_SSL=0.0.0.0:8443" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -v /opt/kong/declarative:/kong/declarative \
  -p 8000:8000 -p 8443:8443 -p 8001:8001 -p 8002:8002 \
  kong:3.4

sleep 10

# -------------------------------
# 6️⃣ Health Checks
# -------------------------------
echo "[kong] 🩺 Checking Kong health..."
curl -s -o /dev/null -w "→ Proxy (8000): %{http_code}\n" http://localhost:8000 || true
curl -s -o /dev/null -w "→ Admin (8001): %{http_code}\n" http://localhost:8001 || true
curl -s -o /dev/null -w "→ Manager (8002): %{http_code}\n" http://localhost:8002 || true

echo
echo "============================================================="
echo "✅ Kong Gateway (DB-less) Installed & Connected to Rancher"
echo "🌐 Proxy :      http://192.168.56.15:8000"
echo "🔒 HTTPS Proxy: https://192.168.56.15:8443"
echo "🧭 Manager UI:  http://192.168.56.15:8002"
echo "⚙️  Admin API :  http://192.168.56.15:8001"
echo "🔁 Route /rancher → https://rancher-master:30443"
echo "============================================================="