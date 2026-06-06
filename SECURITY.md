# Security Policy

## Supported Versions

Security fixes are provided for the latest released version.

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |
| Earlier versions | No |

## Reporting a Vulnerability

Do not open a public issue for a vulnerability that could expose Docker hosts,
firewall rules, private keys, or remote root access. Use GitHub's private
vulnerability reporting feature for this repository.

Include the affected version or commit, reproduction steps, expected impact,
and suggested mitigation when available. Do not include live credentials,
certificates, hostnames, or public IP addresses.

## Security Model

This installer runs as root and changes APT sources, Docker, systemd, and UFW.
Review and pin a commit before executing it on a production host.

Docker client certificates provide root-equivalent control of the server.
Protect the generated client archive and private key as privileged credentials.

The installer restricts Docker TLS port `2376/tcp` to explicitly supplied IPv4
addresses. Operators remain responsible for:

- supplying trusted and stable source addresses;
- preserving SSH access before enabling UFW;
- protecting the server outside UFW, including provider firewalls;
- securely transferring and storing Docker client credentials;
- reviewing local firewall and Docker configuration before rerunning.
