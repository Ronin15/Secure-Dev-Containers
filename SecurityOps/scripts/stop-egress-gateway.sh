#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

"${RUNTIME}" stop -t 2 "${GATEWAY_NAME}" >/dev/null 2>&1 || true
"${RUNTIME}" rm -f "${GATEWAY_NAME}" >/dev/null 2>&1 || true

if "${RUNTIME}" network inspect "${FORENSIC_NETWORK}" >/dev/null 2>&1; then
  "${RUNTIME}" network rm "${FORENSIC_NETWORK}" >/dev/null 2>&1 || true
fi
