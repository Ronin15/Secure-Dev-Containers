#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${PROJECT_ROOT}/distrobox.ini"
BOX_NAME="${SECURITYOPS_DEVBOX_NAME:-securityops-dev}"

if ! command -v distrobox >/dev/null 2>&1; then
  echo "distrobox is required to create and enter the SecurityOps dev shell." >&2
  exit 1
fi

usage() {
  cat <<EOF
Usage: start-dev-shell.sh [--command CMD...]

Builds the SecurityOps dev shell image, assembles the Distrobox template, then opens the shell.

Examples:
  ./scripts/start-dev-shell.sh
  ./scripts/start-dev-shell.sh --command bash -lc 'cd SecurityOps && ./scripts/run-offline.sh --help'
EOF
}

if (( $# > 0 )) && [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
  exit 0
fi

ENTER_COMMAND=()
if (( $# > 0 )); then
  if [[ "$1" != "--command" ]]; then
    echo "Unknown argument: $1" >&2
    usage
    exit 1
  fi
  shift
  if (( $# == 0 )); then
    echo "--command requires at least one argument" >&2
    exit 1
  fi
  ENTER_COMMAND=("$@")
fi

if [[ -x "${SCRIPT_DIR}/build-dev-shell.sh" ]]; then
  "${SCRIPT_DIR}/build-dev-shell.sh"
else
  echo "Missing build-dev-shell.sh helper." >&2
  exit 1
fi

distrobox assemble create --replace --file "${MANIFEST}"

if (( ${#ENTER_COMMAND[@]} > 0 )); then
  distrobox enter "${BOX_NAME}" -- "${ENTER_COMMAND[@]}"
else
  distrobox enter "${BOX_NAME}"
fi
