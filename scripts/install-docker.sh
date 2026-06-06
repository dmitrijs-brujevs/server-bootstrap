#!/usr/bin/env bash

install_docker() {
  local architecture
  local keyring="/etc/apt/keyrings/docker.asc"
  local repository="/etc/apt/sources.list.d/docker.list"
  local temporary_keyring

  log "Installing required host packages."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    openssl \
    ufw

  install -m 0755 -d /etc/apt/keyrings
  log "Installing Docker's repository signing key."
  temporary_keyring=$(mktemp)
  curl -fsSL --retry 3 https://download.docker.com/linux/ubuntu/gpg \
    -o "$temporary_keyring"
  install -m 0644 "$temporary_keyring" "$keyring"
  rm -f "$temporary_keyring"

  architecture=$(dpkg --print-architecture)
  # VERSION_CODENAME is provided by /etc/os-release in validate_host.
  printf 'deb [arch=%s signed-by=%s] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$architecture" "$keyring" "$VERSION_CODENAME" > "$repository"

  log "Installing Docker Engine and the Compose plugin."
  apt-get update
  apt-get install -y --no-install-recommends \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

  systemctl enable --now docker
}
