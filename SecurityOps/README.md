# Forensics & Incident Response Analysis Container

This repository module provides a hardened, lightweight **Linux-only** analysis sandbox for malware triage with:

- Rootless-first container runtime support (Podman preferred, Docker compatible)
- Offline mode with external network disabled by default
- Optional allowlist-based egress profile through a local Squid gateway
- Read-only container root filesystem and dropped capabilities
- Automated evidence capture (inspect, logs, process state, diff, tarball)

Windows analysis is intentionally not part of this module and should be handled in a separate containerized Windows workflow.

## Quick setup

1. Build required images:

```bash
./scripts/build.sh
```

2. Run an offline analysis:

```bash
./scripts/run-offline.sh --sample /path/to/sample.bin
```

3. Run analysis with restricted DNS+HTTP(S) allowlist (through local proxy):

```bash
./scripts/run-controlled-egress.sh --sample /path/to/sample.bin
```

## Default security controls

- Read-only root filesystem in container
- `no-new-privileges`
- `--cap-drop ALL`
- Private PID/network namespace behavior (`network_mode: none` in offline mode)
- Temp filesystems for `/tmp` and `/analysis`
- Host workspace mounted read-write only for explicit output path

## Generated artifact bundle

Each run writes artifacts under `artifacts/<timestamp>/` and creates:

- `artifacts/inspect.json`
- `artifacts/logs.txt`
- `artifacts/ps.txt`
- `artifacts/top.txt`
- `artifacts/diff.txt`
- `artifacts/stats.txt`
- `artifacts/metadata.txt`
- `evidence-<container>.tar.gz`

## Important note

The controlled egress mode forces traffic through the local proxy. Keep `config/allowed-domains.txt` explicit and minimal; an empty allowlist blocks all outbound by default.

## Files

- `Containerfile` - analysis image
- `Containerfile.proxy` - Squid proxy image for egress allowlist mode
- `windows/` - optional Windows binary execution helper (ZeroWine-first, Wine fallback)
- `compose.offline.yml` - docker/podman compose for offline mode
- `compose.egress.yml` - compose for allowlist egress mode
- `config/squid.conf` - Squid ACL configuration
- `config/allowed-domains.txt` - editable allowlist
- `scripts/*` - execution and maintenance helpers

## Windows file execution (separate track)

The Linux container is intentionally kept lightweight and Linux-only.
For Windows binaries, use `SecurityOps/windows/`:

- Build and run Windows PE binaries with Wine compatibility tooling.
- Use only for lightweight compatibility triage.
- For full behavioral analysis, use a dedicated Windows OS environment (separate effort).
