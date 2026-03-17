#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

SESSION_DIR="${SESSION_DIR:-${FORENSIC_EVIDENCE_ROOT}/${GATEWAY_NAME}}"

stop_local_proxy "${SESSION_DIR}"
