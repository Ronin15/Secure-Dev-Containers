#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORENSIC_IMAGE="${FORENSIC_IMAGE:-forensics-sandbox:latest}"
FORENSIC_PROXY_IMAGE="${FORENSIC_PROXY_IMAGE:-forensics-squid-proxy:latest}"
FORENSIC_EVIDENCE_ROOT="${FORENSIC_EVIDENCE_ROOT:-${PROJECT_ROOT}/artifacts}"
FORENSIC_SESSION_PREFIX="${FORENSIC_SESSION_PREFIX:-irf}"
FORENSIC_NETWORK="${FORENSIC_NETWORK:-forensics-egress}"
GATEWAY_NAME="${GATEWAY_NAME:-forensics-proxy}"

detect_runtime() {
  if [[ -n "${FORCE_RUNTIME:-}" ]]; then
    if ! command -v "${FORCE_RUNTIME}" >/dev/null 2>&1; then
      echo "Requested runtime '${FORCE_RUNTIME}' is not available." >&2
      return 1
    fi
    echo "${FORCE_RUNTIME}"
    return 0
  fi

  if command -v podman >/dev/null 2>&1; then
    echo "podman"
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    echo "docker"
    return 0
  fi

  echo "No supported runtime found. Install podman or docker." >&2
  return 1
}

RUNTIME="${RUNTIME:-$(detect_runtime)}"

new_session_name() {
  local suffix
  suffix="$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}${RANDOM}"
  printf "%s-%s" "${FORENSIC_SESSION_PREFIX}" "${suffix}"
}

ensure_images() {
  if ! "${RUNTIME}" image inspect "${FORENSIC_IMAGE}" >/dev/null 2>&1; then
    "${RUNTIME}" build -t "${FORENSIC_IMAGE}" -f "${PROJECT_ROOT}/Containerfile" "${PROJECT_ROOT}"
  fi
}

collect_evidence() {
  local container_name="$1"
  local session_dir="$2"
  local artifacts_dir="${session_dir}/artifacts"
  local tar_items=(artifacts output workspace)

  mkdir -p "${artifacts_dir}"
  {
    printf 'runtime=%s\n' "${RUNTIME}"
    printf 'container=%s\n' "${container_name}"
    printf 'collection_utc=%s\n' "$(date -u -Iseconds)"
  } > "${artifacts_dir}/metadata.txt"

  "${RUNTIME}" inspect "${container_name}" > "${artifacts_dir}/inspect.json" 2>&1 || true
  "${RUNTIME}" logs "${container_name}" > "${artifacts_dir}/logs.txt" 2>&1 || true
  "${RUNTIME}" ps -a --filter "name=${container_name}" > "${artifacts_dir}/ps.txt" 2>&1 || true
  "${RUNTIME}" top "${container_name}" --no-stream > "${artifacts_dir}/top.txt" 2>&1 || true
  "${RUNTIME}" diff "${container_name}" > "${artifacts_dir}/diff.txt" 2>&1 || true
  "${RUNTIME}" stats --no-stream "${container_name}" > "${artifacts_dir}/stats.txt" 2>&1 || true
  (cd "${session_dir}" && find . -maxdepth 2 -type f -print0 | xargs -0 sha256sum > "${artifacts_dir}/sha256sums.txt") || true

  if [[ -d "${session_dir}/input" ]]; then
    tar_items+=(input)
  fi

  tar -C "${session_dir}" -czf "${session_dir}/evidence-${container_name}.tar.gz" "${tar_items[@]}"
  sha256sum "${session_dir}/evidence-${container_name}.tar.gz" > "${artifacts_dir}/checksums.txt" || true
}

cleanup_container() {
  local container_name="$1"
  "${RUNTIME}" stop -t 2 "${container_name}" >/dev/null 2>&1 || true
  "${RUNTIME}" rm -f "${container_name}" >/dev/null 2>&1 || true
}

build_session_dir() {
  local session_name="$1"
  local root="${FORENSIC_EVIDENCE_ROOT}/${session_name}"
  mkdir -p "${root}/input" "${root}/workspace" "${root}/output" "${root}/artifacts"
  printf '%s\n' "${root}"
}
