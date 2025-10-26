#!/bin/bash
set -e

echo "-----------------------------------------------------"
echo " 🚀 Installing and Configuring MinIO Standalone Setup "
echo "-----------------------------------------------------"

# Load environment variables
source /opt/config/minio.env

# Create MinIO directories
sudo mkdir -p /usr/local/bin /etc/minio /var/lib/minio
sudo mkdir -p ${MINIO_VOLUMES}

# Download MinIO server binary
echo "📦 Downloading MinIO server..."
wget -q https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio

# Download MinIO client (mc)
echo "📦 Downloading MinIO client (mc)..."
wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
sudo chmod +x /usr/local/bin/mc

# Create MinIO systemd service
echo "🧩 Creating systemd service..."
sudo tee /etc/systemd/system/minio.service > /dev/null <<EOF
[Unit]
Description=MinIO Object Storage Server
Documentation=https://min.io/docs/
After=network.target

[Service]
User=root
Group=root
EnvironmentFile=/opt/config/minio.env
ExecStart=/usr/local/bin/minio server \$MINIO_VOLUMES --console-address ":9001"
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable minio
sudo systemctl start minio

# Wait for MinIO to start
sleep 5

# Configure MinIO client alias
echo "🔧 Configuring MinIO client alias..."
mc alias set local http://127.0.0.1:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD --api s3v4

# Display status and endpoints
echo "-----------------------------------------------------"
echo " ✅ MinIO Installation Completed!"
echo "-----------------------------------------------------"
echo "🌐 Web UI: http://192.168.56.70:9001"
echo "🪪 Access Key: $MINIO_ROOT_USER"
echo "🔑 Secret Key: $MINIO_ROOT_PASSWORD"
echo "📁 Data Directory: $MINIO_VOLUMES"
echo "-----------------------------------------------------"

sudo systemctl status minio --no-pager
