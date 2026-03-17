#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

if (( $# == 0 )); then
  echo "Usage: clean-workspace.sh <session-name-or-path> [session-name-or-path...]"
  echo "Usage: clean-workspace.sh --all [to remove all session directories]"
  exit 1
fi

remove_session_path() {
  local target="$1"
  local path

  if [[ -d "$target" ]]; then
    path="$target"
  else
    path="${FORENSIC_EVIDENCE_ROOT}/${target}"
  fi

  if [[ -e "$path" ]]; then
    rm -rf "$path"
  fi
}

if [[ "$1" == "--all" ]]; then
  find "${FORENSIC_EVIDENCE_ROOT}" -mindepth 1 -maxdepth 1 -type d -name "${FORENSIC_SESSION_PREFIX}-*" -exec rm -rf {} +
  exit 0
fi

while (( $# > 0 )); do
  remove_session_path "$1"
  shift
done
