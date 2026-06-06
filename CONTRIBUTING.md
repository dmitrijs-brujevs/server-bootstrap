# Contributing

Contributions are welcome through issues and pull requests.

## Development

The project intentionally uses Bash and standard Ubuntu utilities. Keep changes
compatible with Ubuntu 24.04 or newer, systemd, Docker Engine from Docker's
official repository, and UFW.

Before submitting a change, run:

```bash
bash -n install.sh scripts/*.sh
shellcheck install.sh scripts/*.sh
./install.sh --help
./install.sh --version
git diff --check
```

Run full installation tests only on a disposable Ubuntu VPS. The installer
changes APT repositories, Docker, systemd, and firewall rules and can interrupt
remote access or running workloads.

Never commit generated certificates, private keys, client archives, environment
files containing secrets, or real infrastructure addresses.

## Pull Requests

- Keep changes focused and use clear commit messages in the imperative mood.
- Update `README.md` when arguments, defaults, supported hosts, or security
  assumptions change.
- Add user-visible changes to the `Unreleased` section of `CHANGELOG.md`.
- Document testing of SSH access and Docker API restrictions when changing UFW.
- Document rerun and failure behavior when changing Docker TLS provisioning.
- Do not add convenience packages that are outside the project's stated scope.
