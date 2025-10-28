#!/bin/bash
# ---------------------------------------------------
# MongoDB Provision Script — Hybrid (Online + Airgap)
# ---------------------------------------------------
set -e

echo ">>> [1/8] System update & dependencies"
sudo apt-get update -y
sudo apt-get install -y wget curl apt-transport-https gnupg lsb-release

echo ">>> [2/8] Adding MongoDB 6.0 repository and key"
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | \
sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt-get update -y

# ---------------------------------------------
# ONLINE PHASE — Download packages for airgap
# ---------------------------------------------
echo ">>> [3/8] Downloading MongoDB .deb packages (online phase)"
mkdir -p /opt/sync
cd /opt/sync

# Download all MongoDB debs (no install yet)
apt-get download mongodb-org mongodb-org-server mongodb-org-mongos mongodb-org-shell mongodb-org-tools mongodb-org-database

echo "✅ Packages downloaded to /opt/sync"
ls -lh /opt/sync/*.deb

# -------------------------------------------------
# AIRGAP PHASE — Wait for manual internet cutoff
# -------------------------------------------------
echo ""
echo "-----------------------------------------------------------"
echo "🟡  Packages are ready."
echo "🔌  TURN OFF your Internet now to simulate Airgap Environment."
echo "⏳  Waiting 10 seconds..."
echo "-----------------------------------------------------------"
sleep 10
echo ""

# ---------------------------------------------
# OFFLINE INSTALLATION USING DOWNLOADED DEBS
# ---------------------------------------------
echo ">>> [4/8] Installing MongoDB from local .deb files"
sudo dpkg -i /opt/sync/mongodb-org*.deb || sudo apt-get -f install -y

# ---------------------------------------------
# POST-INSTALL CONFIGURATION
# ---------------------------------------------
echo ">>> [5/8] Enabling and starting MongoDB service"
sudo systemctl enable mongod
sudo systemctl start mongod
sleep 5

echo ">>> [6/8] Checking MongoDB service"
if systemctl is-active --quiet mongod; then
  echo "✅ MongoDB service is running"
else
  echo "❌ MongoDB failed to start!"
  exit 1
fi

echo ">>> [7/8] Configuring database permissions and inserting test data"
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chmod -R 755 /var/lib/mongodb

mongosh <<EOF
use internDB
db.createCollection("students")
db.students.insertOne({ name: "Maaz", role: "DevOps Intern (Hybrid Airgap)" })
EOF

echo ">>> [8/8] Cleanup & Summary"
systemctl status mongod --no-pager | grep Active
echo "✅ MongoDB Hybrid Airgap Setup Completed Successfully!"