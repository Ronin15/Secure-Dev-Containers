#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORENSIC_EVIDENCE_ROOT="${FORENSIC_EVIDENCE_ROOT:-${PROJECT_ROOT}/artifacts}"
FORENSIC_SESSION_PREFIX="${FORENSIC_SESSION_PREFIX:-irf}"
FORENSIC_PROXY_PORT="${FORENSIC_PROXY_PORT:-3128}"
GATEWAY_NAME="${GATEWAY_NAME:-forensics-proxy}"

new_session_name() {
  local suffix
  suffix="$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}${RANDOM}"
  printf "%s-%s" "${FORENSIC_SESSION_PREFIX}" "${suffix}"
}

build_session_dir() {
  local session_name="$1"
  local root="${FORENSIC_EVIDENCE_ROOT}/${session_name}"
  mkdir -p "${root}/input" "${root}/output" "${root}/artifacts"
  printf '%s\n' "${root}"
}

generate_proxy_config() {
  local session_dir="$1"
  local artifacts_dir="${session_dir}/artifacts"
  local proxy_conf="${artifacts_dir}/squid.conf"
  local proxy_acl="${artifacts_dir}/allowed-domains.acl"
  local proxy_log="${artifacts_dir}/proxy-access.log"
  local proxy_pid="${artifacts_dir}/squid.pid"

  mkdir -p "${artifacts_dir}"
  cp "${PROJECT_ROOT}/config/allowed-domains.txt" "${proxy_acl}"

  awk -v acl_path="${proxy_acl}" -v log_path="${proxy_log}" '
    /^acl allowed_domains dstdomain / {
      printf "acl allowed_domains dstdomain \"%s\"\n", acl_path
      next
    }
    /^access_log / {
      printf "access_log stdio:%s\n", log_path
      next
    }
    {
      print
    }
  ' "${PROJECT_ROOT}/config/squid.conf" > "${proxy_conf}"

  if ! grep -q '^pid_filename ' "${proxy_conf}"; then
    printf 'pid_filename %s\n' "${proxy_pid}" >> "${proxy_conf}"
  fi

  if ! grep -q '^access_log ' "${proxy_conf}"; then
    printf 'access_log stdio:%s\n' "${proxy_log}" >> "${proxy_conf}"
  fi

  if ! grep -q '^acl allowed_domains dstdomain ' "${proxy_conf}"; then
    printf 'acl allowed_domains dstdomain "%s"\n' "${proxy_acl}" >> "${proxy_conf}"
  fi

  printf '%s\n' "${proxy_conf}"
}

wait_for_proxy_ready() {
  local attempts=20
  local i=1

  while (( i <= attempts )); do
    if (exec 3<>"/dev/tcp/127.0.0.1/${FORENSIC_PROXY_PORT}") 2>/dev/null; then
      exec 3>&-
      exec 3<&-
      return 0
    fi
    sleep 1
    ((i += 1))
  done

  return 1
}

start_local_proxy() {
  local session_dir="$1"
  local artifacts_dir="${session_dir}/artifacts"
  local proxy_conf
  local proxy_pid_file="${artifacts_dir}/squid.pid"

  proxy_conf="$(generate_proxy_config "${session_dir}")"

  if [[ -f "${proxy_pid_file}" ]] && kill -0 "$(cat "${proxy_pid_file}")" >/dev/null 2>&1; then
    return 0
  fi

  squid -N -f "${proxy_conf}" \
    >"${artifacts_dir}/proxy.stdout" \
    2>"${artifacts_dir}/proxy.stderr" &
  local squid_pid=$!
  echo "${squid_pid}" > "${proxy_pid_file}"

  if wait_for_proxy_ready; then
    return 0
  fi

  echo "Proxy gateway failed readiness check." >&2
  [[ -f "${artifacts_dir}/proxy.stderr" ]] && cat "${artifacts_dir}/proxy.stderr" >&2 || true
  kill "${squid_pid}" >/dev/null 2>&1 || true
  rm -f "${proxy_pid_file}" >/dev/null 2>&1 || true
  return 1
}

stop_local_proxy() {
  local session_dir="$1"
  local artifacts_dir="${session_dir}/artifacts"
  local proxy_pid_file="${artifacts_dir}/squid.pid"

  if [[ -f "${proxy_pid_file}" ]]; then
    local pid
    pid="$(cat "${proxy_pid_file}")"
    kill "${pid}" >/dev/null 2>&1 || true
    wait "${pid}" >/dev/null 2>&1 || true
    rm -f "${proxy_pid_file}" >/dev/null 2>&1 || true
  fi
}

collect_evidence() {
  local session_name="$1"
  local session_dir="$2"
  local artifacts_dir="${session_dir}/artifacts"
  local tar_items=(artifacts output input)
  local safe_tar_items=()

  mkdir -p "${artifacts_dir}"
  mkdir -p "${session_dir}/output" "${session_dir}/input"
  {
    printf 'mode=container-shell\n'
    printf 'session=%s\n' "${session_name}"
    printf 'collection_utc=%s\n' "$(date -u -Iseconds)"
    printf 'hostname=%s\n' "$(hostname 2>/dev/null || true)"
    printf 'user=%s\n' "$(id -un 2>/dev/null || true)"
    printf 'uid=%s\n' "$(id -u 2>/dev/null || true)"
    printf 'gid=%s\n' "$(id -g 2>/dev/null || true)"
    printf 'pwd=%s\n' "$(pwd)"
  } > "${artifacts_dir}/metadata.txt"

  uname -a > "${artifacts_dir}/uname.txt" 2>&1 || true
  id > "${artifacts_dir}/id.txt" 2>&1 || true
  ps -ef > "${artifacts_dir}/ps.txt" 2>&1 || true
  top -b -n 1 > "${artifacts_dir}/top.txt" 2>&1 || true
  lsof -nP > "${artifacts_dir}/lsof.txt" 2>&1 || true
  ip addr > "${artifacts_dir}/ip-addr.txt" 2>&1 || true
  ip route > "${artifacts_dir}/ip-route.txt" 2>&1 || true

  if [[ -f "${artifacts_dir}/proxy-access.log" ]]; then
    cp "${artifacts_dir}/proxy-access.log" "${artifacts_dir}/proxy-access.log.snapshot" 2>/dev/null || true
  fi

  (cd "${session_dir}" && find . -maxdepth 3 -type f -print0 | xargs -0 sha256sum > "${artifacts_dir}/sha256sums.txt") || true

  for item in "${tar_items[@]}"; do
    if [[ -e "${session_dir}/${item}" ]]; then
      safe_tar_items+=("${item}")
    fi
  done

  tar -C "${session_dir}" -czf "${session_dir}/evidence-${session_name}.tar.gz" "${safe_tar_items[@]}"
  sha256sum "${session_dir}/evidence-${session_name}.tar.gz" > "${artifacts_dir}/checksums.txt" || true
}
