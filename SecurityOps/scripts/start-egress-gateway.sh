#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

ensure_images

if ! "${RUNTIME}" network inspect "${FORENSIC_NETWORK}" >/dev/null 2>&1; then
  "${RUNTIME}" network create "${FORENSIC_NETWORK}" >/dev/null
fi

wait_for_proxy_ready() {
  local attempts=20
  local i=1

  while (( i <= attempts )); do
    if "${RUNTIME}" exec "${GATEWAY_NAME}" squid -k check -f /etc/squid/squid.conf >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    ((i += 1))
  done

  return 1
}

if "${RUNTIME}" container inspect "${GATEWAY_NAME}" >/dev/null 2>&1; then
  if [[ "$("${RUNTIME}" inspect --format '{{.State.Running}}' "${GATEWAY_NAME}" 2>/dev/null || true)" != "true" ]]; then
    "${RUNTIME}" start "${GATEWAY_NAME}" >/dev/null
  fi
  echo "Gateway already exists: ${GATEWAY_NAME}"
  if wait_for_proxy_ready; then
    exit 0
  fi
  echo "Existing gateway failed readiness check." >&2
  "${RUNTIME}" logs "${GATEWAY_NAME}" >&2 || true
  exit 1
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

if wait_for_proxy_ready; then
  exit 0
fi

echo "Proxy gateway failed to become ready." >&2
"${RUNTIME}" logs "${GATEWAY_NAME}" >&2 || true
"${RUNTIME}" rm -f "${GATEWAY_NAME}" >/dev/null 2>&1 || true
exit 1
