# Server Bootstrap

Bootstrap a fresh Ubuntu 24.04 or newer VPS as a production Docker host with
Docker mutual TLS and a source-restricted UFW firewall.

Current release: `v1.0.1`.

## Usage

At least one trusted public IPv4 address is required:

```bash
curl -fsSL https://raw.githubusercontent.com/dmitrijs-brujevs/server-bootstrap/main/install.sh \
  | sudo bash -s -- \
      --docker-api-allow-ip 65.109.6.202
```

Allow multiple client addresses:

```bash
curl -fsSL https://raw.githubusercontent.com/dmitrijs-brujevs/server-bootstrap/main/install.sh \
  | sudo bash -s -- \
      --docker-api-allow-ip 65.109.6.202 \
      --docker-api-allow-ip 84.15.120.55
```

The installer detects the server's public IPv4 address through
`https://api.ipify.org`. Override it when necessary:

```bash
curl -fsSL https://raw.githubusercontent.com/dmitrijs-brujevs/server-bootstrap/main/install.sh \
  | sudo bash -s -- \
      --server-ip 203.0.113.10 \
      --docker-api-allow-ip 65.109.6.202
```

Arguments after a pipe must follow `bash -s --`. The shorter
`curl ... | sudo bash` form cannot supply the mandatory allowed IP.

For a reproducible bootstrap, replace `main` in the first URL and set the same
commit in `SERVER_BOOTSTRAP_REF`:

```bash
curl -fsSL https://raw.githubusercontent.com/dmitrijs-brujevs/server-bootstrap/YOUR_COMMIT/install.sh \
  | sudo env SERVER_BOOTSTRAP_REF=YOUR_COMMIT bash -s -- \
      --docker-api-allow-ip 65.109.6.202
```

Running a remote script as root grants it complete control of the host. Pin and
review a commit before using this on production infrastructure.

## What It Configures

- Docker Engine from Docker's official Ubuntu repository
- Docker Compose plugin
- Docker mutual TLS on `tcp://0.0.0.0:2376`
- UFW defaults: deny incoming and allow outgoing
- SSH on `22/tcp`
- Docker TLS on `2376/tcp` only from explicitly supplied IPv4 addresses

The installer explicitly installs only these host prerequisites:

- `curl`
- `ca-certificates`
- `gnupg`
- `openssl`
- `ufw`

It also installs Docker's required packages: `containerd.io`, `docker-ce`,
`docker-ce-cli`, and `docker-compose-plugin`. APT may install package
dependencies required by those packages.

## Reruns

The installer is safe to rerun. It updates Docker packages and replaces only
the UFW source rules previously managed by this project. Existing Docker TLS
credentials are preserved so rerunning does not silently rotate the CA or
invalidate clients.

The generated client bundle is:

```text
/etc/docker/tls/active/project-admin-docker-client.tar.gz
```

Anyone holding the client private key has root-equivalent control through
Docker. Transfer it over a secure channel and protect it as a privileged
credential.

## Validation

The installer validates the services before printing its summary. Manual checks:

```bash
docker version
docker compose version
systemctl status docker
ss -tulpn | grep 2376
ufw status
```

## Development

Run from a checked-out repository:

```bash
sudo ./install.sh --docker-api-allow-ip 65.109.6.202
```

Static checks:

```bash
bash -n install.sh scripts/*.sh
shellcheck install.sh scripts/*.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes. User-visible
changes are tracked in [CHANGELOG.md](CHANGELOG.md).

## Security

Read [SECURITY.md](SECURITY.md) before deployment and use GitHub private
vulnerability reporting for security issues. Do not publish host addresses,
client certificates, private keys, or other live credentials in an issue.

## License

Licensed under the [MIT License](LICENSE).
