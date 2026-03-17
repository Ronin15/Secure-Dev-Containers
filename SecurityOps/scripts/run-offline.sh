#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage: run-offline.sh [--sample PATH] [--output PATH] [--command CMD...]

Runs the workflow command directly inside the secure shell context with no proxy settings.
The outer container context should already be offline or network-restricted.

Examples:
  ./run-offline.sh --sample /tmp/suspicious.exe
  ./run-offline.sh --sample /tmp/suspicious.exe --command /bin/bash -lc "sha256sum input/suspicious.exe"
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

cleanup_done=0
cleanup_analysis() {
  if [[ "${cleanup_done}" -eq 0 ]]; then
    cleanup_done=1
    collect_evidence "${SESSION_NAME}" "${SESSION_DIR}" || true
  fi
}
trap 'cleanup_analysis' EXIT INT TERM

echo "Starting offline workflow in shell context: ${SESSION_NAME}"
echo "Evidence bundle path: ${SESSION_DIR}"

set +e
(cd "${SESSION_DIR}" && env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u all_proxy "${COMMAND[@]}")
RUN_EXIT=$?
set -e

cleanup_analysis
exit "${RUN_EXIT}"
