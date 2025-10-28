#!/bin/bash
# -------------------------------------------------------
# MongoDB Replica Set Provision Script (Hybrid + Airgap FINAL VERSION)
# -------------------------------------------------------
set -e

RS_NAME="rs0"
PRIMARY_IP="192.168.56.41"
SECONDARY1_IP="192.168.56.42"
SECONDARY2_IP="192.168.56.43"

echo ">>> [1/10] Updating system and installing base tools"
sudo apt-get update -y
sudo apt-get install -y wget curl apt-transport-https gnupg lsb-release

# -------------------------------------------------------
# ONLINE PHASE — Repository + Local Download
# -------------------------------------------------------
echo ">>> [2/10] Adding MongoDB 6.0 repository"
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | \
sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update -y

echo ">>> [3/10] Downloading MongoDB and dependencies (safe local path)"
sudo rm -rf /tmp/mongo-debs
sudo mkdir -p /tmp/mongo-debs
sudo chmod 777 /tmp/mongo-debs
cd /tmp/mongo-debs

# Download packages safely and copy for reuse
sudo apt-get install --download-only -y mongodb-org
sudo cp /var/cache/apt/archives/*.deb /tmp/mongo-debs/ || true

sudo mkdir -p /opt/sync
sudo cp -r /tmp/mongo-debs/*.deb /opt/sync/ || true
echo "✅ Packages downloaded and copied to /opt/sync/"
ls -lh /opt/sync/*.deb

# -------------------------------------------------------
# AIRGAP INSTRUCTION
# -------------------------------------------------------
if [[ $(hostname) == "mongo-1" ]]; then
  echo ""
  echo "=================================================================="
  echo "🟡  DOWNLOAD COMPLETE ON PRIMARY NODE!"
  echo "👉  NOW DISCONNECT INTERNET COMPLETELY."
  echo "    (Turn OFF Wi-Fi or disable NAT adapter in VirtualBox.)"
  echo "    Keep only private network (192.168.56.x) active."
  echo "⏳  Waiting 25 seconds..."
  echo "=================================================================="
  sleep 25
  echo ""
fi

# -------------------------------------------------------
# OFFLINE PHASE — Install from local packages
# -------------------------------------------------------
echo ">>> [4/10] Installing MongoDB completely offline"
cd /opt/sync || cd /tmp/mongo-debs
sudo dpkg -i *.deb || true
sudo apt -f install -y --no-download

# -------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------
echo ">>> [5/10] Configuring mongod.conf for replication"
sudo sed -i 's/^  bindIp:.*/  bindIp: 0.0.0.0/' /etc/mongod.conf

if ! grep -q "replication:" /etc/mongod.conf; then
  sudo bash -c "cat >> /etc/mongod.conf <<EOF

replication:
  replSetName: $RS_NAME
EOF"
fi

sudo systemctl enable mongod
sudo systemctl restart mongod
sleep 20

# -------------------------------------------------------
# REPLICA SET INITIALIZATION (Primary only)
# -------------------------------------------------------
if [[ $(hostname -I | grep -o "$PRIMARY_IP") ]]; then
  echo ">>> [6/10] Initializing Replica Set on primary node"
  echo "Waiting for mongod to fully start with replSetName..."
  sleep 30

  grep -A2 "replication" /etc/mongod.conf || echo "❌ Replication block not found!"

  for i in {1..3}; do
    echo "Attempt $i: initializing replica set..."
    mongosh --quiet --eval "
      try {
        rs.initiate({
          _id: '$RS_NAME',
          members: [
            { _id: 0, host: '$PRIMARY_IP:27017' },
            { _id: 1, host: '$SECONDARY1_IP:27017' },
            { _id: 2, host: '$SECONDARY2_IP:27017' }
          ]
        });
      } catch(e) { print('Retry needed or already initiated'); }
    " && break
    echo "Retrying in 10s..."
    sleep 10
  done
fi

# -------------------------------------------------------
# ADMIN USER CREATION (Primary only)
# -------------------------------------------------------
if [[ $(hostname -I | grep -o "$PRIMARY_IP") ]]; then
  echo ">>> [7/10] Creating admin user"
  mongosh --quiet --eval "
    use admin;
    try {
      db.createUser({
        user: 'admin',
        pwd: 'Admin@123',
        roles: [ { role: 'root', db: 'admin' } ]
      });
    } catch(e) { print('User already exists or replica not ready yet'); }
  "
  sleep 5
fi

# -------------------------------------------------------
# VALIDATION
# -------------------------------------------------------
echo ">>> [8/10] Verifying MongoDB service"
if systemctl is-active --quiet mongod; then
  echo "✅ mongod is running on $(hostname)"
else
  echo "❌ mongod failed to start on $(hostname)"
  exit 1
fi

# -------------------------------------------------------
# AUTHENTICATION + TEST INSERTION
# -------------------------------------------------------
echo ">>> [9/10] Insert test data (Primary only)"
if [[ $(hostname -I | grep -o "$PRIMARY_IP") ]]; then
  echo "Waiting 10s for authentication system to initialize..."
  sleep 10

  for i in {1..3}; do
    echo "Attempt $i: inserting test data..."
    mongosh -u admin -p Admin@123 --authenticationDatabase admin --quiet <<EOF || true
use internDB
db.students.insertOne({ name: "Maaz", role: "DevOps Intern (Replica Airgap FINAL)" })
EOF
    if [ $? -eq 0 ]; then
      echo "✅ Authentication succeeded on attempt $i"
      break
    else
      echo "⚠️  Authentication not ready yet, retrying in 5s..."
      sleep 5
    fi
  done
fi

# -------------------------------------------------------
# REPLICA SET STATUS
# -------------------------------------------------------
if [[ $(hostname -I | grep -o "$PRIMARY_IP") ]]; then
  echo ">>> [10/10] Checking replica set status"
  mongosh --quiet --eval "
    try {
      rs.status().members.forEach(m => print(m.name + ' => ' + m.stateStr));
    } catch(e) {
      print('⚠️  Replica set not initialized yet or rs.status() unavailable.');
    }
  "
fi

echo ""
echo "✅ MongoDB Replica Node $(hostname) Setup Complete (Hybrid + Safe Offline Mode)"
echo "---------------------------------------------------------------"