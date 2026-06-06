#!/usr/bin/env bash
set -Eeuo pipefail

readonly SERVER_BOOTSTRAP_REF="${SERVER_BOOTSTRAP_REF:-main}"
readonly SERVER_BOOTSTRAP_REPOSITORY="${SERVER_BOOTSTRAP_REPOSITORY:-dmitrijs-brujevs/server-bootstrap}"
readonly VERSION="1.0.0"

SCRIPT_DIR=""
DOWNLOAD_DIR=""
SERVER_IP=""
declare -a DOCKER_API_ALLOW_IPS=()

usage() {
  cat <<'EOF'
Usage:
  curl -fsSL https://raw.githubusercontent.com/dmitrijs-brujevs/server-bootstrap/main/install.sh \
    | sudo bash -s -- \
        [--server-ip 203.0.113.10] \
        --docker-api-allow-ip 198.51.100.10 \
        [--docker-api-allow-ip 198.51.100.11]

Options:
  --server-ip              Public IPv4 address for the Docker TLS certificate.
                           Detected automatically when omitted.
  --docker-api-allow-ip    IPv4 address allowed to reach Docker TCP port 2376.
                           Required and repeatable.
  --version                Print the installer version.
  --help, -h               Show this help.
EOF
}

log() {
  printf '[server-bootstrap] %s\n' "$*"
}

fail() {
  printf '[server-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [ -n "$DOWNLOAD_DIR" ] && [ -d "$DOWNLOAD_DIR" ]; then
    rm -rf "$DOWNLOAD_DIR"
  fi
}

trap cleanup EXIT

argument_value() {
  local option="$1"
  local value="${2-}"

  [ -n "$value" ] || fail "Missing value for $option."
  printf '%s\n' "$value"
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --server-ip)
        SERVER_IP=$(argument_value "$1" "${2-}")
        shift 2
        ;;
      --docker-api-allow-ip)
        DOCKER_API_ALLOW_IPS+=("$(argument_value "$1" "${2-}")")
        shift 2
        ;;
      --version)
        printf 'server-bootstrap %s\n' "$VERSION"
        exit 0
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  [ "${#DOCKER_API_ALLOW_IPS[@]}" -gt 0 ] ||
    fail "At least one --docker-api-allow-ip address is required."
}

require_root() {
  [ "$(id -u)" -eq 0 ] || fail "Run this installer as root."
}

load_scripts() {
  local source_dir
  local script
  local raw_base

  source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)
  if [ -n "$source_dir" ] && [ -f "$source_dir/scripts/common.sh" ]; then
    SCRIPT_DIR="$source_dir/scripts"
    return
  fi

  command -v curl >/dev/null 2>&1 ||
    fail "curl is required to download the bootstrap modules."

  DOWNLOAD_DIR=$(mktemp -d)
  SCRIPT_DIR="$DOWNLOAD_DIR/scripts"
  mkdir -p "$SCRIPT_DIR"
  raw_base="https://raw.githubusercontent.com/${SERVER_BOOTSTRAP_REPOSITORY}/${SERVER_BOOTSTRAP_REF}/scripts"

  for script in common.sh install-docker.sh configure-firewall.sh install-docker-tls.sh; do
    log "Downloading scripts/$script."
    curl -fsSL --retry 3 --output "$SCRIPT_DIR/$script" "$raw_base/$script"
  done
}

main() {
  parse_arguments "$@"
  require_root
  load_scripts

  # shellcheck source=scripts/common.sh
  source "$SCRIPT_DIR/common.sh"
  # shellcheck source=scripts/install-docker.sh
  source "$SCRIPT_DIR/install-docker.sh"
  # shellcheck source=scripts/configure-firewall.sh
  source "$SCRIPT_DIR/configure-firewall.sh"
  # shellcheck source=scripts/install-docker-tls.sh
  source "$SCRIPT_DIR/install-docker-tls.sh"

  validate_host
  validate_ipv4_list "${DOCKER_API_ALLOW_IPS[@]}"

  if [ -n "$SERVER_IP" ]; then
    validate_ipv4 "--server-ip" "$SERVER_IP"
  else
    SERVER_IP=$(detect_public_ipv4)
  fi

  install_docker
  configure_firewall "${DOCKER_API_ALLOW_IPS[@]}"
  install_docker_tls "$SERVER_IP"
  validate_installation
  print_summary "$SERVER_IP" "${DOCKER_API_ALLOW_IPS[@]}"
}

main "$@"
