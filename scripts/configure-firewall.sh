#!/usr/bin/env bash

readonly FIREWALL_STATE_DIR="/etc/server-bootstrap"
readonly FIREWALL_STATE_FILE="$FIREWALL_STATE_DIR/docker-api-allow-ips"

remove_previous_docker_api_rules() {
  local address

  [ -f "$FIREWALL_STATE_FILE" ] || return 0

  while IFS= read -r address; do
    [ -n "$address" ] || continue
    if validate_ipv4 "Stored Docker API IP" "$address" 2>/dev/null; then
      ufw --force delete allow from "$address" to any port "$DOCKER_TLS_PORT" proto tcp ||
        true
    fi
  done < "$FIREWALL_STATE_FILE"
}

configure_firewall() {
  local address
  local temporary_state

  log "Configuring UFW."
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp

  remove_previous_docker_api_rules
  install -d -m 0700 "$FIREWALL_STATE_DIR"
  temporary_state=$(mktemp "$FIREWALL_STATE_DIR/.docker-api-allow-ips.XXXXXX")

  for address in "$@"; do
    ufw allow from "$address" to any port "$DOCKER_TLS_PORT" proto tcp
    printf '%s\n' "$address" >> "$temporary_state"
  done

  chmod 0600 "$temporary_state"
  mv "$temporary_state" "$FIREWALL_STATE_FILE"
  ufw --force enable

  if ufw status | grep -Eq "^${DOCKER_TLS_PORT}/tcp.*ALLOW IN.*Anywhere"; then
    fail "Unsafe public Docker API firewall rule detected for port $DOCKER_TLS_PORT."
  fi
}
