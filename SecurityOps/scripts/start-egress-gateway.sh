#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

SESSION_DIR="${SESSION_DIR:-${FORENSIC_EVIDENCE_ROOT}/${GATEWAY_NAME}}"
mkdir -p "${SESSION_DIR}/input" "${SESSION_DIR}/output" "${SESSION_DIR}/artifacts"

echo "Starting local proxy gateway in shell context: ${GATEWAY_NAME}"
start_local_proxy "${SESSION_DIR}"
