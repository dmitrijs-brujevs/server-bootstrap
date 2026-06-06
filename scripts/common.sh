#!/usr/bin/env bash

readonly DOCKER_TLS_PORT="2376"

log() {
  printf '[server-bootstrap] %s\n' "$*"
}

fail() {
  printf '[server-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

validate_ipv4() {
  local option="$1"
  local address="$2"
  local octets=()
  local octet

  IFS=. read -r -a octets <<< "$address"
  [ "${#octets[@]}" -eq 4 ] ||
    fail "$option is not a valid IPv4 address: $address"

  for octet in "${octets[@]}"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] ||
      fail "$option is not a valid IPv4 address: $address"
    [ "$((10#$octet))" -le 255 ] ||
      fail "$option is not a valid IPv4 address: $address"
  done
}

validate_ipv4_list() {
  local address

  [ "$#" -gt 0 ] ||
    fail "At least one --docker-api-allow-ip address is required."

  for address in "$@"; do
    validate_ipv4 "--docker-api-allow-ip" "$address"
  done
}

validate_host() {
  [ "$(id -u)" -eq 0 ] || fail "Run this installer as root."
  [ -r /etc/os-release ] || fail "Cannot identify the operating system."

  # shellcheck source=/dev/null
  source /etc/os-release
  [ "${ID:-}" = "ubuntu" ] || fail "Ubuntu is required."
  [ "${VERSION_ID%%.*}" -ge 24 ] || fail "Ubuntu 24.04 or newer is required."
  [ -d /run/systemd/system ] || fail "A systemd-based host is required."
  [ "$(dpkg --print-architecture)" = "amd64" ] ||
    [ "$(dpkg --print-architecture)" = "arm64" ] ||
    fail "Only amd64 and arm64 architectures are supported."
}

detect_public_ipv4() {
  local address

  log "Detecting the public IPv4 address." >&2
  address=$(curl -4fsS --retry 3 --connect-timeout 5 --max-time 15 https://api.ipify.org) ||
    fail "Public IPv4 detection failed; provide --server-ip."
  validate_ipv4 "Detected public IPv4" "$address"
  printf '%s\n' "$address"
}

validate_installation() {
  local listener

  log "Validating Docker, Compose, TLS listener, and UFW."
  docker version >/dev/null
  docker compose version >/dev/null
  systemctl is-active --quiet docker ||
    fail "Docker is not active after installation."
  listener=$(ss -H -ltn "sport = :$DOCKER_TLS_PORT")
  [ -n "$listener" ] || fail "Docker is not listening on TCP $DOCKER_TLS_PORT."
  ufw status | grep -q '^Status: active$' || fail "UFW is not active."
}

print_summary() {
  local server_ip="$1"
  shift
  local allowed_ips
  local docker_version
  local compose_version
  local firewall_status

  allowed_ips=$(printf '%s, ' "$@")
  allowed_ips=${allowed_ips%, }
  docker_version=$(docker version --format '{{.Server.Version}}')
  compose_version=$(docker compose version --short)
  firewall_status=$(ufw status | sed -n '1p')

  cat <<EOF

Server bootstrap completed.

  Hostname:                $(hostname)
  Public IP:              $server_ip
  Docker version:         $docker_version
  Docker Compose version: $compose_version
  Docker TLS endpoint:    tcp://$server_ip:$DOCKER_TLS_PORT
  Allowed Docker API IPs: $allowed_ips
  Firewall status:        $firewall_status

Client certificate archive:
  /etc/docker/tls/active/project-admin-docker-client.tar.gz

The client certificate grants root-equivalent access. Transfer and store it
as a privileged credential.
EOF
}
