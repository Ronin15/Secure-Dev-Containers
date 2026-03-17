# Forensics & Incident Response Analysis Container

This repository module provides a hardened, lightweight **Linux-only** analysis sandbox for malware triage with:

- Container-shell-first runtime support for DistroShelf-managed Distrobox or Toolbx environments
- A secure dev shell image that carries the supported analysis tooling
- Offline mode with external network disabled by the secure shell context
- Optional allowlist-based egress profile through a local Squid process in the same shell
- Read-only container root filesystem and dropped capabilities
- Automated evidence capture (shell state, process/network state, checksums, tarball)

Windows analysis is intentionally not part of this module and should be handled in a separate containerized Windows workflow.

## Quick setup

1. Enter the secure shell context:

```bash
./scripts/start-dev-shell.sh
```

2. Run an offline analysis from inside that shell:

```bash
./scripts/run-offline.sh --sample /path/to/sample.bin
```

3. Run analysis with restricted DNS+HTTP(S) allowlist (through local proxy):

```bash
./scripts/run-controlled-egress.sh --sample /path/to/sample.bin
```

## Container shell workflow

This project is intended to be run from inside a container shell environment.

The secure dev shell image is the buildable workflow image; it carries the supported tools and is used to create the shell context where the scripts run.

To generate and enter the Distrobox template:

```bash
./scripts/start-dev-shell.sh
```

If you use DistroShelf, Distrobox, or Toolbx, open the repository inside that shell and run the scripts there.

## Default security controls

- Read-only root filesystem in the secure shell image
- `no-new-privileges`
- `--cap-drop ALL`
- Offline runs are expected to execute in a shell context that was started without network access
- Controlled egress runs use a local Squid process and explicit proxy environment variables
- Session roots contain real `input/`, `output/`, and `artifacts/` directories
- Evidence stays under the session directory unless you explicitly set `--output`

## Generated artifact bundle

Each run writes artifacts under `artifacts/<timestamp>/` and creates:

- `artifacts/uname.txt`
- `artifacts/id.txt`
- `artifacts/ps.txt`
- `artifacts/top.txt`
- `artifacts/lsof.txt`
- `artifacts/ip-addr.txt`
- `artifacts/ip-route.txt`
- `artifacts/metadata.txt`
- `artifacts/sha256sums.txt`
- `artifacts/checksums.txt`
- `evidence-<container>.tar.gz`

## Important note

The controlled egress mode forces traffic through the local Squid process. Keep `config/allowed-domains.txt` explicit and minimal; an empty allowlist blocks all outbound by default.

## Files

- `distrobox.ini` - Distrobox template for the SecurityOps container shell
- `dev/Containerfile` - secure SecurityOps dev-shell image
- `Containerfile` - analysis base image used by the secure shell build
- `windows/` - optional Windows binary execution helper (ZeroWine-first, Wine fallback)
- `config/squid.conf` - Squid ACL configuration
- `config/allowed-domains.txt` - editable allowlist
- `scripts/build.sh` - build the secure dev shell image
- `scripts/build-dev-shell.sh` - build the SecurityOps dev-shell image
- `scripts/start-dev-shell.sh` - generate and enter the Distrobox shell
- `scripts/*` - execution and maintenance helpers

## Windows file execution (separate track)

The Linux container is intentionally kept lightweight and Linux-only.
For Windows binaries, use `SecurityOps/windows/`:

- Build and run Windows PE binaries with Wine compatibility tooling.
- Use only for lightweight compatibility triage.
- For full behavioral analysis, use a dedicated Windows OS environment (separate effort).
