#!/usr/bin/env bash

readonly DOCKER_TLS_SETUP_REF="f0a386b41dd2ad1e76dc97eed61ee64763626768"
readonly DOCKER_TLS_SETUP_URL="https://raw.githubusercontent.com/dmitrijs-brujevs/docker-tls-setup/${DOCKER_TLS_SETUP_REF}/docker-tls-setup.sh"
readonly DOCKER_TLS_SETUP_BIN="/usr/local/sbin/docker-tls-setup"
readonly DOCKER_TLS_OVERRIDE="/etc/systemd/system/docker.service.d/10-docker-tls.conf"
readonly DOCKER_TLS_CERT_ROOT="/etc/docker/tls"

docker_tls_is_configured() {
  [ -f "$DOCKER_TLS_OVERRIDE" ] &&
    [ -f "$DOCKER_TLS_CERT_ROOT/active/ca.pem" ] &&
    [ -f "$DOCKER_TLS_CERT_ROOT/active/server-cert.pem" ] &&
    [ -f "$DOCKER_TLS_CERT_ROOT/active/server-key.pem" ] &&
    [ -f "$DOCKER_TLS_CERT_ROOT/active/cert.pem" ] &&
    [ -f "$DOCKER_TLS_CERT_ROOT/active/key.pem" ]
}

install_docker_tls() {
  local server_ip="$1"
  local temporary_script

  if docker_tls_is_configured; then
    openssl x509 \
      -in "$DOCKER_TLS_CERT_ROOT/active/server-cert.pem" \
      -noout \
      -checkip "$server_ip" >/dev/null ||
      fail "Existing Docker TLS certificate does not contain server IP $server_ip."
    log "Docker TLS is already configured; preserving the existing CA and client certificate."
    systemctl restart docker
    return
  fi

  if [ -e "$DOCKER_TLS_OVERRIDE" ] || [ -e "$DOCKER_TLS_CERT_ROOT/active" ]; then
    fail "Partial Docker TLS configuration detected. Repair or remove it before rerunning."
  fi

  log "Installing pinned Docker TLS setup utility."
  temporary_script=$(mktemp)
  curl -fsSL --retry 3 --output "$temporary_script" "$DOCKER_TLS_SETUP_URL"
  install -m 0755 "$temporary_script" "$DOCKER_TLS_SETUP_BIN"
  rm -f "$temporary_script"

  log "Configuring Docker mutual TLS on TCP $DOCKER_TLS_PORT."
  "$DOCKER_TLS_SETUP_BIN" \
    --server-ip "$server_ip" \
    --port "$DOCKER_TLS_PORT"
}
