#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FORENSIC_IMAGE="${FORENSIC_IMAGE:-forensics-sandbox:latest}"
DEV_SHELL_IMAGE="${DEV_SHELL_IMAGE:-securityops-dev-shell:latest}"
DEV_SHELL_CONTAINERFILE="${PROJECT_ROOT}/dev/Containerfile"

detect_runtime() {
  if [[ -n "${FORCE_RUNTIME:-}" ]]; then
    if ! command -v "${FORCE_RUNTIME}" >/dev/null 2>&1; then
      echo "Requested runtime '${FORCE_RUNTIME}' is not available." >&2
      exit 1
    fi
    printf '%s\n' "${FORCE_RUNTIME}"
    return 0
  fi

  if command -v podman >/dev/null 2>&1; then
    printf '%s\n' "podman"
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    printf '%s\n' "docker"
    return 0
  fi

  echo "No supported runtime found for image build." >&2
  exit 1
}

RUNTIME="${RUNTIME:-$(detect_runtime)}"

echo "Building analysis base image: ${FORENSIC_IMAGE}"
"${RUNTIME}" build -t "${FORENSIC_IMAGE}" -f "${PROJECT_ROOT}/Containerfile" "${PROJECT_ROOT}"

echo "Building dev shell image: ${DEV_SHELL_IMAGE}"
"${RUNTIME}" build \
  --build-arg BASE_IMAGE="${FORENSIC_IMAGE}" \
  -t "${DEV_SHELL_IMAGE}" \
  -f "${DEV_SHELL_CONTAINERFILE}" \
  "${PROJECT_ROOT}"
