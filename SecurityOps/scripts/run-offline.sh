#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage: run-offline.sh [--sample PATH] [--output PATH] [--command CMD...]

Starts an analysis container with no network access.

Examples:
  ./run-offline.sh --sample /tmp/suspicious.exe
  ./run-offline.sh --sample /tmp/suspicious.exe --command /bin/bash -lc "sha256sum /analysis/input/suspicious.exe"
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

mkdir -p "${SESSION_DIR}/workspace" "${SESSION_DIR}/output" "${SESSION_DIR}/artifacts"

if [[ -n "${SAMPLE_PATH}" ]]; then
  if [[ ! -e "${SAMPLE_PATH}" ]]; then
    echo "Sample not found: ${SAMPLE_PATH}" >&2
    exit 1
  fi
  mkdir -p "${SESSION_DIR}/input"
  cp -a "${SAMPLE_PATH}" "${SESSION_DIR}/input/"
fi

ensure_images

RUNTIME_OPTS=(
  --name "${SESSION_NAME}"
  --hostname "${SESSION_NAME}"
  --read-only
  --network none
  --pids-limit "${FORENSIC_PIDS_LIMIT:-1024}"
  --memory "${FORENSIC_MEMORY_LIMIT:-2g}"
  --cpus "${FORENSIC_CPU_LIMIT:-2}"
  --security-opt no-new-privileges:true
  --cap-drop ALL
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size="${FORENSIC_TMPFS_SIZE:-2g}"
  --tmpfs /analysis:rw,noexec,nosuid,nodev,size=1g
  -v "${SESSION_DIR}/workspace:/analysis/workspace:rw"
  -v "${SESSION_DIR}/output:/analysis/output:rw"
)

if [[ -d "${SESSION_DIR}/input" ]]; then
  RUNTIME_OPTS+=(-v "${SESSION_DIR}/input:/analysis/input:ro")
fi

if [[ "${RUNTIME}" == "podman" ]]; then
  RUNTIME_OPTS+=(--userns=keep-id)
fi

echo "Starting offline analysis container: ${SESSION_NAME}"
echo "Evidence bundle path: ${SESSION_DIR}"

set +e
"${RUNTIME}" run -it "${RUNTIME_OPTS[@]}" "${FORENSIC_IMAGE}" "${COMMAND[@]}"
RUN_EXIT=$?
set -e

collect_evidence "${SESSION_NAME}" "${SESSION_DIR}"
cleanup_container "${SESSION_NAME}"
exit "${RUN_EXIT}"
