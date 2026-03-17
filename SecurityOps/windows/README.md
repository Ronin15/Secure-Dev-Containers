# Optional Windows Execution Track

This directory is intentionally separate from the Linux-only `SecurityOps` analysis
container.

Use this module only for lightweight compatibility execution of Windows samples.
Execution is **ZeroWine-first** with Wine fallback.
For high-confidence behavioral analysis, use a true Windows OS sandbox VM/host
(separate effort).

## Build

```bash
cd SecurityOps
podman build -t securityops-windows-emul -f windows/Containerfile .
```

## Run

```bash
cd SecurityOps
./windows/run-windows.sh /path/to/sample.exe
```

## ZeroWine runtime

By default, the launcher tries `zerowine` inside the container first.
If `zerowine` is unavailable, it falls back to `wine64` and then `wine`.

To use a real ZeroWine stack, extend `SecurityOps/windows/Containerfile` and
install your approved ZeroWine package or copy a pinned binary into the image.
