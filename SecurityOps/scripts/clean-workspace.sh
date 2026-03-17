#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

if (( $# == 0 )); then
  echo "Usage: clean-workspace.sh <container-name-or-id> [container-name-or-id...]"
  echo "Usage: clean-workspace.sh --all [to remove all stopped forensics containers]"
  exit 1
fi

if [[ "$1" == "--all" ]]; then
  ids="$("${RUNTIME}" ps -a --filter "name=${FORENSIC_SESSION_PREFIX}" -q)"
  if [[ -n "${ids}" ]]; then
    "${RUNTIME}" rm -f ${ids} >/dev/null || true
  fi
  exit 0
fi

while (( $# > 0 )); do
  "${RUNTIME}" rm -f "$1"
  shift
done
