#!/bin/bash
echo "🔧 Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git unzip net-tools apt-transport-https ca-certificates gnupg lsb-release