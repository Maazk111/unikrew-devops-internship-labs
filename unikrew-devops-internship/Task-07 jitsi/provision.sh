#!/bin/bash
# 🧩 Jitsi Meet Dockerized Lab Provision Script
set -e

echo "🔹 Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo "🔹 Installing dependencies..."
sudo apt install -y docker.io docker-compose git curl

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Create Jitsi directory
mkdir -p /home/vagrant/jitsi
cd /home/vagrant/jitsi

echo "🔹 Setting up environment file..."
cat <<EOF > .env
HTTP_PORT=8000
HTTPS_PORT=8443
PUBLIC_URL=https://192.168.56.80
ENABLE_AUTH=0
ENABLE_GUESTS=1
JICOFO_AUTH_PASSWORD=securepass
JVB_AUTH_PASSWORD=securepass
EOF

echo "🔹 Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3'

services:
  web:
    image: jitsi/web:stable
    restart: unless-stopped
    ports:
      - "\${HTTP_PORT}:80"
      - "\${HTTPS_PORT}:443"
    environment:
      - PUBLIC_URL=\${PUBLIC_URL}
      - ENABLE_GUESTS=\${ENABLE_GUESTS}
    depends_on:
      - prosody
      - jicofo
      - jvb
    networks:
      - meet.jitsi

  prosody:
    image: jitsi/prosody:stable
    restart: unless-stopped
    expose:
      - '5222'
      - '5347'
      - '5280'
    environment:
      - AUTH_TYPE=anonymous
    networks:
      - meet.jitsi

  jicofo:
    image: jitsi/jicofo:stable
    restart: unless-stopped
    depends_on:
      - prosody
    environment:
      - JICOFO_AUTH_PASSWORD=\${JICOFO_AUTH_PASSWORD}
    networks:
      - meet.jitsi

  jvb:
    image: jitsi/jvb:stable
    restart: unless-stopped
    ports:
      - "10000:10000/udp"
    environment:
      - JVB_AUTH_PASSWORD=\${JVB_AUTH_PASSWORD}
    depends_on:
      - prosody
    networks:
      - meet.jitsi

networks:
  meet.jitsi:
EOF


echo "🔹 Starting Jitsi Stack via Docker Compose..."
sudo docker-compose up -d

echo "✅ Jitsi Meet setup complete!"
echo "🌐 Access it at: https://192.168.56.80:8443"
echo "⚙️ Use 'vagrant ssh' → 'cd /home/vagrant/jitsi' → 'docker-compose logs -f' to view logs."
