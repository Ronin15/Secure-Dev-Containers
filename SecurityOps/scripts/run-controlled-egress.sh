#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage: run-controlled-egress.sh [--sample PATH] [--output PATH] [--command CMD...]

Starts the local Squid gateway inside the secure shell context, then runs the workflow command
with proxy variables pointed at that gateway.
EOF
}

SAMPLE_PATH=""
COMMAND=(/bin/bash)
OUTPUT_DIR=""

while (( $# > 0 )); do
  case "$1" in
    --sample)
      SAMPLE_PATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --command)
      shift
      if (( $# == 0 )); then
        echo "--command requires at least one argument" >&2
        exit 1
      fi
      COMMAND=("$@")
      break
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

mkdir -p "${FORENSIC_EVIDENCE_ROOT}"
SESSION_NAME="$(new_session_name)"

if [[ -z "${OUTPUT_DIR}" ]]; then
  SESSION_DIR="${FORENSIC_EVIDENCE_ROOT}/${SESSION_NAME}"
else
  SESSION_DIR="${OUTPUT_DIR}"
fi

mkdir -p "${SESSION_DIR}/input" "${SESSION_DIR}/output" "${SESSION_DIR}/artifacts"

if [[ -n "${SAMPLE_PATH}" ]]; then
  if [[ ! -e "${SAMPLE_PATH}" ]]; then
    echo "Sample not found: ${SAMPLE_PATH}" >&2
    exit 1
  fi
  mkdir -p "${SESSION_DIR}/input"
  cp -a "${SAMPLE_PATH}" "${SESSION_DIR}/input/"
fi

cleanup_full() {
  if [[ "${cleanup_done}" -eq 0 ]]; then
    cleanup_done=1
    stop_local_proxy "${SESSION_DIR}" || true
    collect_evidence "${SESSION_NAME}" "${SESSION_DIR}" || true
  fi
}
cleanup_done=0
trap 'cleanup_full' EXIT INT TERM

echo "Starting controlled egress workflow in shell context: ${SESSION_NAME}"
echo "Evidence bundle path: ${SESSION_DIR}"

start_local_proxy "${SESSION_DIR}"

set +e
(cd "${SESSION_DIR}" && env \
  http_proxy="http://127.0.0.1:${FORENSIC_PROXY_PORT}" \
  https_proxy="http://127.0.0.1:${FORENSIC_PROXY_PORT}" \
  HTTP_PROXY="http://127.0.0.1:${FORENSIC_PROXY_PORT}" \
  HTTPS_PROXY="http://127.0.0.1:${FORENSIC_PROXY_PORT}" \
  ALL_PROXY="http://127.0.0.1:${FORENSIC_PROXY_PORT}" \
  all_proxy="http://127.0.0.1:${FORENSIC_PROXY_PORT}" \
  "${COMMAND[@]}")
RUN_EXIT=$?
set -e

cleanup_full
exit "${RUN_EXIT}"
