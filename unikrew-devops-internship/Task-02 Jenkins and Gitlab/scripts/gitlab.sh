#!/bin/bash
echo "📦 Installing GitLab CE..."
sudo apt-get update -y
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://gitlab.local" apt-get install -y gitlab-ce
sudo gitlab-ctl reconfigure
echo "✅ GitLab installed and running at http://gitlab.local"