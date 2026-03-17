# Optional Windows Execution Track

This directory is intentionally separate from the Linux-only `SecurityOps` shell workflow.

Use this module only for lightweight compatibility execution of Windows samples.
Execution is **ZeroWine-first** with Wine fallback.
For high-confidence behavioral analysis, use a true Windows OS sandbox VM or host
(separate effort).

## Build

```bash
cd SecurityOps
./windows/run-windows.sh /path/to/sample.exe
```

The first run builds `securityops-windows-emul:latest` if it is missing.

## ZeroWine runtime

By default, the launcher tries `zerowine` inside the image first.
If `zerowine` is unavailable, it falls back to `wine64` and then `wine`.

To use a real ZeroWine stack, extend `SecurityOps/windows/Containerfile` and
install your approved ZeroWine package or copy a pinned binary into the image.
