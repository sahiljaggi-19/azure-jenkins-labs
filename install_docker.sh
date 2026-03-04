#!/usr/bin/env bash
set -euo pipefail

# --- Config / helpers ---
UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$(lsb_release -cs)}")"
ARCH="$(dpkg --print-architecture)"
KEYRING="/etc/apt/keyrings/docker.gpg"
REPO_LIST="/etc/apt/sources.list.d/docker.list"
CURRENT_USER="${SUDO_USER:-$USER}"   # works when run via sudo or directly

echo "==> Updating APT and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "==> Adding Docker’s official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "${KEYRING}"
sudo chmod a+r "${KEYRING}"

echo "==> Setting up the Docker APT repository (${UBUNTU_CODENAME}, ${ARCH})..."
echo "deb [arch=${ARCH} signed-by=${KEYRING}] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
  | sudo tee "${REPO_LIST}" >/dev/null

echo "==> Refreshing package index..."
sudo apt-get update -y

echo "==> Installing Docker Engine, CLI, containerd, Buildx and Compose plugins..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Enabling and starting the Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Ensure /var/run/docker.sock has the expected ownership/permissions
echo "==> Verifying docker.sock ownership and permissions..."
if [[ -S /var/run/docker.sock ]]; then
  sudo chown root:docker /var/run/docker.sock || true
  sudo chmod 660 /var/run/docker.sock || true
fi

echo "==> Adding '${CURRENT_USER}' to the 'docker' group (if not already)..."
if id -nG "${CURRENT_USER}" | grep -qw docker; then
  echo "    User '${CURRENT_USER}' is already in group 'docker'."
else
  sudo usermod -aG docker "${CURRENT_USER}"
  echo "    Added. You must log out and log back in (or run 'newgrp docker' in your shell) to use Docker without sudo."
fi

# Optional: one-shot test if group is already effective *in this shell*.
# This will succeed if you were already in the docker group before running the script,
# or if you manually re-exec the shell after 'newgrp docker'.
echo "==> Testing Docker (this may fail if your current session hasn’t picked up new group membership)..."
if docker info >/dev/null 2>&1; then
  docker run --rm hello-world || true
else
  echo "    Docker is installed and running, but your current shell likely lacks 'docker' group membership yet."
  echo "    Open a new terminal or run:  newgrp docker"
fi

echo "==> Done."
