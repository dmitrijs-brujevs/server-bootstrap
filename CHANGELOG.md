# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

### Security

## [1.0.0] - 2026-06-06

### Added

- Single-command bootstrap for Ubuntu 24.04 or newer Docker hosts.
- Docker Engine installation from Docker's official Ubuntu repository.
- Docker Compose plugin installation.
- Modular Bash implementation for host validation, Docker installation, UFW
  configuration, and Docker mutual TLS setup.
- Automatic public IPv4 detection with an explicit `--server-ip` override.
- Required, repeatable `--docker-api-allow-ip` arguments with complete IPv4
  validation before firewall changes.
- UFW defaults that deny incoming traffic, allow outgoing traffic, permit SSH
  on `22/tcp`, and restrict Docker TLS on `2376/tcp` to trusted source IPs.
- Pinned integration with `docker-tls-setup` for reproducible TLS provisioning.
- Idempotent reruns that preserve existing Docker TLS credentials and replace
  only Docker API source rules previously managed by this project.
- Post-installation validation for Docker, Compose, systemd, the TLS listener,
  and UFW.
- Installation summary with hostname, public IP, component versions, endpoint,
  allowed client IPs, and firewall status.
- `--version` output for identifying the installed release.
- Repository documentation, contribution guidelines, security policy, MIT
  license, editor settings, line-ending rules, and secret-aware ignore rules.

### Security

- Docker API access requires mutual TLS and is never intentionally allowed from
  an unrestricted source.
- All supplied and detected IPv4 addresses are validated before firewall rules
  are applied.
- The installer rejects unsupported hosts before installing packages or
  changing services.
- Existing Docker TLS credentials are preserved on rerun to prevent accidental
  CA rotation and client invalidation.
- The Docker TLS setup utility is downloaded from a pinned commit.

[Unreleased]: https://github.com/dmitrijs-brujevs/server-bootstrap/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/dmitrijs-brujevs/server-bootstrap/releases/tag/v1.0.0
