#!/bin/bash

set -e

echo "🔄 Updating system packages..."
sudo apt update -y
sudo apt install -y gnupg software-properties-common curl

echo "🔑 Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "📦 Adding HashiCorp repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "⬇️ Installing Terraform..."
sudo apt update -y
sudo apt install -y terraform

echo "✅ Terraform installation complete!"
echo "📌 Installed version:"
terraform version
