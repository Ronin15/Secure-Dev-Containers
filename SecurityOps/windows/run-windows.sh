#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${RUNTIME:-}"

detect_runtime() {
  if [[ -n "${FORCE_RUNTIME:-}" ]]; then
    if command -v "${FORCE_RUNTIME}" >/dev/null 2>&1; then
      echo "${FORCE_RUNTIME}"
      return 0
    fi
    echo "Requested runtime '${FORCE_RUNTIME}' is not available." >&2
    return 1
  fi
  if command -v podman >/dev/null 2>&1; then
    echo "podman"
  elif command -v docker >/dev/null 2>&1; then
    echo "docker"
  else
    echo "No supported runtime found." >&2
    return 1
  fi
}

if [[ -z "${RUNTIME}" ]]; then
  RUNTIME="$(detect_runtime)"
fi

if (( $# != 1 )); then
  echo "Usage: run-windows.sh /path/to/file.exe" >&2
  exit 1
fi

SAMPLE_PATH="$1"
if [[ ! -f "${SAMPLE_PATH}" ]]; then
  echo "Sample not found: ${SAMPLE_PATH}" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WINDOWS_IMAGE="${WINDOWS_IMAGE:-securityops-windows-emul:latest}"
WORKDIR="${WORKDIR:-${PROJECT_ROOT}/windows-workdir}"
ZEROWINE_CMD="${ZEROWINE_CMD:-zerowine}"
IMAGE_ENTRY="${IMAGE_ENTRY:-bash -lc}"
mkdir -p "${WORKDIR}"
mkdir -p "${WORKDIR}/input" "${WORKDIR}/output"
cp -a "${SAMPLE_PATH}" "${WORKDIR}/input/"

if ! "${RUNTIME}" image inspect "${WINDOWS_IMAGE}" >/dev/null 2>&1; then
  echo "Building Windows emulation image: ${WINDOWS_IMAGE}"
  "${RUNTIME}" build -t "${WINDOWS_IMAGE}" -f "${PROJECT_ROOT}/windows/Containerfile" "${PROJECT_ROOT}"
fi

FNAME="$(basename "${SAMPLE_PATH}")"

"${RUNTIME}" run --rm \
  --name "ir-windows-emul-$(date +%s)" \
  --read-only \
  --tmpfs /analysis:rw,noexec,nosuid,nodev,size=1g,uid=1000,gid=1000,mode=700 \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size=1g \
  -v "${WORKDIR}/input:/analysis/input:ro" \
  -v "${WORKDIR}/output:/analysis/output:rw" \
  -e WINEDEBUG=-all \
  -e HOME=/home/forensics \
  -e WINEPREFIX=/analysis/wineprefix \
  -e ZEROWINE_CMD="${ZEROWINE_CMD}" \
  "${WINDOWS_IMAGE}" \
  ${IMAGE_ENTRY} \
  "if command -v \"${ZEROWINE_CMD}\" >/dev/null 2>&1; then \
     DISPLAY=:99 xvfb-run -a \"${ZEROWINE_CMD}\" /analysis/input/${FNAME}; \
   elif command -v wine64 >/dev/null 2>&1; then \
     DISPLAY=:99 xvfb-run -a wine64 /analysis/input/${FNAME}; \
   elif command -v wine >/dev/null 2>&1; then \
     DISPLAY=:99 xvfb-run -a wine /analysis/input/${FNAME}; \
   else \
     echo \"No Windows runtime available\" >&2; \
     exit 1; \
   fi"
