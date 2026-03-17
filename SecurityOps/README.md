# Forensics & Incident Response Analysis Container

This repository provides a hardened analysis sandbox for malware triage with:

- Rootless-first container runtime support (Podman preferred, Docker compatible)
- Offline mode with external network disabled by default
- Optional allowlist-based egress profile through a local Squid gateway
- Read-only container root filesystem and dropped capabilities
- Automated evidence capture (inspect, logs, process state, diff, tarball)

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

The controlled egress mode is intended to force traffic through the local proxy, but any
direct network path controls outside the proxy should be reviewed for your threat model and host policy.

## Files

- `Containerfile` - analysis image
- `Containerfile.proxy` - Squid proxy image for egress allowlist mode
- `compose.offline.yml` - docker/podman compose for offline mode
- `compose.egress.yml` - compose for allowlist egress mode
- `config/squid.conf` - Squid ACL configuration
- `config/allowed-domains.txt` - editable allowlist
- `scripts/*` - execution and maintenance helpers
