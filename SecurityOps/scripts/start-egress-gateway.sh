#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

ensure_images

if ! "${RUNTIME}" network inspect "${FORENSIC_NETWORK}" >/dev/null 2>&1; then
  "${RUNTIME}" network create "${FORENSIC_NETWORK}" >/dev/null
fi

if "${RUNTIME}" container inspect "${GATEWAY_NAME}" >/dev/null 2>&1; then
  "${RUNTIME}" start "${GATEWAY_NAME}" >/dev/null
  echo "Gateway already exists: ${GATEWAY_NAME}"
  exit 0
fi

echo "Starting proxy gateway: ${GATEWAY_NAME}"
"${RUNTIME}" run -d \
  --name "${GATEWAY_NAME}" \
  --hostname "${GATEWAY_NAME}" \
  --network "${FORENSIC_NETWORK}" \
  --network-alias proxy \
  --read-only \
  --tmpfs /var/log/squid:rw,noexec,nosuid,nodev,size=1g \
  --tmpfs /var/spool/squid:rw,noexec,nosuid,nodev,size=2g \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  "${FORENSIC_PROXY_IMAGE}"

sleep 2
