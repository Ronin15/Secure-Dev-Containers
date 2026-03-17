# Secure-Dev-Containers

This repository is a central catalog for secure containerization patterns, including
hardening guidance for both secure development and security operations workloads.

- Secure Development Containers: templates, hardening baseline patterns, and practical
  examples for safe containerized development.
- Security Operations: a dedicated isolation-first analysis environment for digital
  forensics and incident response (malware triage).

Current implemented module:

- [SecurityOps](SecurityOps/)
  - [Distrobox container shell template](SecurityOps/distrobox.ini)
  - [SecurityOps dev shell image](SecurityOps/dev/Containerfile)
  - [Analysis base image](SecurityOps/Containerfile)
  - [Analysis scripts](SecurityOps/scripts/)
  - [Proxy/evidence/allowlist config](SecurityOps/config/)
  - [SecurityOps setup guide](SecurityOps/README.md)
  - [Optional Windows execution track](SecurityOps/windows/README.md)

## SecurityOps quick start

The SecurityOps module provides a hardened analysis sandbox intended to be run from a container shell environment such as DistroShelf-managed Distrobox or Toolbx:

- Use `./scripts/start-dev-shell.sh` to build the secure dev shell image and enter the container shell context
- Run the project from inside that shell
- Offline-by-default mode is enforced by the secure shell context itself
- Optional controlled egress mode via a local Squid process in the same shell
- Read-only container filesystem, dropped Linux capabilities, and automated evidence capture

```bash
cd SecurityOps
./scripts/start-dev-shell.sh
./scripts/run-offline.sh --sample /path/to/sample.bin
```

For controlled egress:

```bash
cd SecurityOps
./scripts/run-controlled-egress.sh --sample /path/to/sample.bin
```

If you are launching from DistroShelf, open the project inside that container shell and run the same scripts there.

To generate the container shell template and enter it:

```bash
cd SecurityOps
./scripts/start-dev-shell.sh
```

For setup and behavior details:

- [SecurityOps README](SecurityOps/README.md)

## What’s included

- A secure dev shell image that carries the supported workflow tools.
- A container shell template that is created from that image.
- Container-first analysis workflow.
- Offline-by-default analysis mode with no external network.
- Optional controlled egress mode using a local Squid allowlist gateway in the same shell.
- Read-only container root filesystem and dropped Linux capabilities.
- Automated post-run forensic evidence capture.

## Quick start

```bash
cd SecurityOps
./scripts/start-dev-shell.sh
./scripts/run-offline.sh --sample /path/to/sample.bin
```

For controlled egress:

```bash
cd SecurityOps
./scripts/run-controlled-egress.sh --sample /path/to/sample.bin
```

For setup, usage details, and security caveats, use the SecurityOps readme.
