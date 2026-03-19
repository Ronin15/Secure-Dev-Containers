# Secure-Dev-Containers

This repository is a central catalog for secure containerization patterns, including
hardening guidance for both secure development and security operations workloads. ......... WORK IN PROGRESS

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

- Build the secure dev shell image and enter the container shell with `./scripts/start-dev-shell.sh`
- Run all workflow scripts from inside that shell
- Offline mode uses the shell context directly
- Controlled egress starts a local Squid process in the same shell
- Read-only filesystem, dropped Linux capabilities, and automated evidence capture are built into the workflow

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

For setup and behavior details:

- [SecurityOps README](SecurityOps/README.md)

## What’s included

- A secure dev shell image that carries the supported workflow tools.
- A container shell template created from that image.
- A shell-first analysis workflow.
- Offline analysis mode with no external network.
- Controlled egress mode using a local Squid process in the same shell.
- Read-only container root filesystem and dropped Linux capabilities.
- Automated post-run forensic evidence capture.

## Quick start

```bash
cd SecurityOps
./scripts/start-dev-shell.sh
./scripts/run-offline.sh --sample /path/to/sample.bin
```
