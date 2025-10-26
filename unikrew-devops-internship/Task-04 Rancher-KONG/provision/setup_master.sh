#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="192.168.56.10"
RANCHER_HOSTNAME="rancher.local"
REGISTRY_PORT="5000"
REGISTRY_DIR="/opt/registry"
REGISTRY_CFG_DIR="/opt/registry-cfg"
K3S_REGISTRIES_FILE="/etc/rancher/k3s/registries.yaml"
SHARED_DIR="/vagrant/shared"

echo "🚀 [master] Starting Rancher Master Setup..."

# ---------------------------------------------------------
# 1️⃣ Install Docker
# ---------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "[master] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  mkdir -p /etc/docker
  cat >/etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["${MASTER_IP}:${REGISTRY_PORT}", "rancher-master:${REGISTRY_PORT}"]
}
EOF
  systemctl enable docker
  systemctl restart docker
fi

# ---------------------------------------------------------
# 2️⃣ Local Registry
# ---------------------------------------------------------
echo "[master] Configuring Local Registry on port ${REGISTRY_PORT}..."
mkdir -p ${REGISTRY_DIR} ${REGISTRY_CFG_DIR}
install -m 0644 /provision/registry/config.yml ${REGISTRY_CFG_DIR}/config.yml

if ! docker ps --format '{{.Names}}' | grep -q '^registry$'; then
  docker run -d --restart=always --name registry \
    -v ${REGISTRY_DIR}:/var/lib/registry \
    -v ${REGISTRY_CFG_DIR}/config.yml:/etc/docker/registry/config.yml \
    -p ${REGISTRY_PORT}:5000 registry:2
fi

# ---------------------------------------------------------
# 3️⃣ Install K3s
# ---------------------------------------------------------
echo "[master] Installing K3s server..."
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

export INSTALL_K3S_EXEC="server --cluster-init \
  --tls-san ${RANCHER_HOSTNAME} --tls-san ${MASTER_IP} \
  --disable traefik --write-kubeconfig-mode=644"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
chmod 644 /etc/rancher/k3s/k3s.yaml

echo "[master] Waiting for K3s API..."
for i in {1..60}; do
  if kubectl get node >/dev/null 2>&1; then
    echo "✅ K3s API ready!"
    break
  fi
  sleep 5
done

echo "[master] Sharing node token..."
mkdir -p "${SHARED_DIR}"
cp /var/lib/rancher/k3s/server/node-token "${SHARED_DIR}/node-token"

# ---------------------------------------------------------
# 4️⃣ Install Helm
# ---------------------------------------------------------
if ! command -v helm >/dev/null 2>&1; then
  echo "[master] Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# ---------------------------------------------------------
# 5️⃣ cert-manager + ClusterIssuer
# ---------------------------------------------------------
echo "[master] Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

echo "[master] Waiting for cert-manager..."
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=180s || true
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=180s || true
kubectl rollout status deployment/cert-manager-cainjector -n cert-manager --timeout=180s || true

echo "[master] Applying self-signed ClusterIssuer..."
kubectl apply -f /vagrant/provision/manifests/issuers-selfsigned.yaml || true

# ---------------------------------------------------------
# 6️⃣ NFS + Provisioner
# ---------------------------------------------------------
apt-get install -y nfs-kernel-server
mkdir -p /srv/nfs
chown -R nobody:nogroup /srv/nfs
chmod 0777 /srv/nfs
echo "/srv/nfs *(rw,sync,no_subtree_check,no_root_squash)" >/etc/exports
exportfs -ra
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-storage --create-namespace \
  --set nfs.server=${MASTER_IP} \
  --set nfs.path=/srv/nfs \
  --set storageClass.name=default \
  --set storageClass.defaultClass=true

# ---------------------------------------------------------
# 7️⃣ Traefik Ingress + TLS
# ---------------------------------------------------------
echo "[master] Installing Traefik..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm upgrade --install traefik traefik/traefik \
  --namespace kube-system \
  --set service.type=LoadBalancer \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443

MASTER_IP=$(hostname -I | awk '{print $2}')
kubectl patch svc traefik -n kube-system -p "{\"spec\": {\"externalIPs\": [\"$MASTER_IP\"]}}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=300s

# ---------------------------------------------------------
# 8️⃣ Rancher TLS (Ingress + CA)
# ---------------------------------------------------------
echo "[master] Creating Rancher certificates..."
mkdir -p /etc/rancher/certs

openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout /etc/rancher/certs/tls.key \
  -out /etc/rancher/certs/tls.crt \
  -subj "/CN=rancher.local"

kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls tls-rancher-ingress \
  --cert=/etc/rancher/certs/tls.crt \
  --key=/etc/rancher/certs/tls.key \
  -n cattle-system --dry-run=client -o yaml | kubectl apply -f -

# ✅ Create the proper CA file (cacerts.pem)
if ! kubectl get secret tls-ca -n cattle-system >/dev/null 2>&1; then
  echo "[master] Creating Rancher CA (cacerts.pem)..."
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout /etc/rancher/certs/cacerts.key \
    -out /etc/rancher/certs/cacerts.pem \
    -subj "/CN=rancher-ca.local"
  kubectl create secret generic tls-ca -n cattle-system \
    --from-file=cacerts.pem=/etc/rancher/certs/cacerts.pem
fi

# ---------------------------------------------------------
# 9️⃣ Install Rancher
# ---------------------------------------------------------
echo "[master] Installing Rancher via Helm..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=${RANCHER_HOSTNAME} \
  --set replicas=1 \
  --set ingress.tls.source=secret \
  --set privateCA=true \
  --set bootstrapPassword=admin

kubectl -n cattle-system rollout status deploy/rancher --timeout=10m || true

# ---------------------------------------------------------
# ✅ Done
# ---------------------------------------------------------
echo
echo "============================================================="
echo "✅ Rancher installation complete!"
echo "🌐 Access URL: https://${RANCHER_HOSTNAME}:30443"
echo "👤 Username: admin"
echo "🔑 Password: admin"
echo "📄 Kubeconfig: /etc/rancher/k3s/k3s.yaml"
echo "============================================================="