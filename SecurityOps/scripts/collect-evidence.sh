#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

if (( $# != 2 )); then
  echo "Usage: collect-evidence.sh <container-name> <output-dir>" >&2
  exit 1
fi

collect_evidence "$1" "$2"
