# Secure-Dev-Containers

This repository is a central catalog for secure containerization patterns, including
hardening guidance for both secure development and security operations workloads.

- Secure Development Containers: templates, hardening baseline patterns, and practical
  examples for safe containerized development.
- Security Operations: a dedicated isolation-first analysis environment for digital
  forensics and incident response (malware triage).

Current implemented module:

- [SecurityOps](SecurityOps/)
  - [Containerfiles and compose profiles](SecurityOps/Containerfile)
  - [Analysis scripts](SecurityOps/scripts/)
  - [Proxy/evidence/allowlist config](SecurityOps/config/)
  - [SecurityOps setup guide](SecurityOps/README.md)
  - [Optional Windows execution track](SecurityOps/windows/README.md)

## SecurityOps quick start

The SecurityOps module provides a hardened, Podman/Docker-compatible analysis sandbox:

- Rootless-first runtime model (Podman preferred, Docker compatible)
- Offline-by-default mode with no external network
- Optional controlled egress mode via local allowlist gateway
- Read-only container filesystem, dropped Linux capabilities, and automated evidence capture

```bash
cd SecurityOps
./scripts/build.sh
./scripts/run-offline.sh --sample /path/to/sample.bin
```

For controlled egress:

```bash
cd SecurityOps
./scripts/run-controlled-egress.sh --sample /path/to/sample.bin
```

For setup and behavior details:

- [SecurityOps README](SecurityOps/README.md)

## What’s included

- Rootless-first runtime model (Podman preferred, Docker compatible).
- Offline-by-default analysis mode with no external network.
- Optional controlled egress mode using a local Squid allowlist gateway.
- Read-only container root filesystem and dropped Linux capabilities.
- Automated post-run forensic evidence capture.

## Quick start

```bash
cd SecurityOps
./scripts/build.sh
./scripts/run-offline.sh --sample /path/to/sample.bin
```

For controlled egress:

```bash
cd SecurityOps
./scripts/run-controlled-egress.sh --sample /path/to/sample.bin
```

For setup, usage details, and security caveats, use the SecurityOps readme.
