#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

echo "Building analysis image: ${FORENSIC_IMAGE}"
"${RUNTIME}" build -t "${FORENSIC_IMAGE}" -f "${PROJECT_ROOT}/Containerfile" "${PROJECT_ROOT}"

echo "Building proxy image: ${FORENSIC_PROXY_IMAGE}"
"${RUNTIME}" build -t "${FORENSIC_PROXY_IMAGE}" -f "${PROJECT_ROOT}/Containerfile.proxy" "${PROJECT_ROOT}"

echo "Build complete."
