#!/bin/bash
set -e

echo "-----------------------------------------------------"
echo " 🧱 COMMON SETUP — Updating and Installing Base Tools "
echo "-----------------------------------------------------"

# Update package index and upgrade existing packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install basic utilities
sudo apt-get install -y \
  curl wget unzip net-tools vim apt-transport-https ca-certificates gnupg lsb-release jq

# Enable system hostname resolution fix for Rancher-style clusters
sudo echo "127.0.0.1 $(hostname)" >> /etc/hosts

# Clean up
sudo apt-get autoremove -y
sudo apt-get clean

echo "✅ Common setup completed successfully."