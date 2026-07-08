#!/usr/bin/env bash
get_public_ipv4() {
  local ip=""
  local providers=("${IPV4_PROVIDER:-https://api.ipify.org}" "https://ipv4.icanhazip.com" "https://checkip.amazonaws.com" "https://ifconfig.me/ip")
  for provider in "${providers[@]}"; do
    ip="$(curl -4 -sS --connect-timeout 10 --max-time 25 "$provider" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then echo "$ip"; return 0; fi
  done
  echo ""
}
get_public_ipv6() {
  local ip=""
  local providers=("${IPV6_PROVIDER:-https://api64.ipify.org}" "https://ipv6.icanhazip.com")
  for provider in "${providers[@]}"; do
    ip="$(curl -6 -sS --connect-timeout 10 --max-time 25 "$provider" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ "$ip" =~ : ]]; then echo "$ip"; return 0; fi
  done
  echo ""
}
is_valid_ipv4(){ [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
is_valid_ipv6(){ [[ "$1" =~ : ]]; }
trim_spaces(){ echo "$1"|xargs; }
verify_dns_propagation(){
  # name type expected_ip proxied — only meaningful for DNS-only records (proxied records resolve to Cloudflare edge IPs)
  local name="$1" type="$2" expected="$3" proxied="$4" got=""
  [[ "${VERIFY_DNS:-no}" != "yes" || "$proxied" == "true" ]] && return 0
  command -v dig >/dev/null 2>&1 || { log_msg WARN "VERIFY_DNS is enabled but dig is not installed; skipping verification."; return 0; }
  expected="$(echo "$expected" | tr '[:upper:]' '[:lower:]')"
  for _ in 1 2 3; do
    got="$(dig +short "$name" "$type" @1.1.1.1 2>/dev/null | head -n1 | tr '[:upper:]' '[:lower:]' || true)"
    [[ "$got" == "$expected" ]] && { log_msg INFO "DNS verified for ${name} ${type}: ${expected}"; return 0; }
    sleep 5
  done
  log_msg WARN "DNS verification failed for ${name} ${type}: resolver returned '${got:-nothing}', expected ${expected}"
  telegram_error "DNS verification failed for ${name} ${type}: resolver sees '${got:-nothing}', expected ${expected}" "${SERVER_NAME:-unknown}"
  return 0
}
json_get_state(){ local k="$1"; [[ -f "${STATE_FILE:-}" ]] && jq -r --arg key "$k" '.[$key] // empty' "$STATE_FILE"; }
json_set_state(){ local k="$1" v="$2"; mkdir -p "$(dirname "$STATE_FILE")"; [[ ! -f "$STATE_FILE" ]] && echo '{}' > "$STATE_FILE"; tmp=$(mktemp); jq --arg key "$k" --arg value "$v" '.[$key]=$value' "$STATE_FILE" > "$tmp"; mv "$tmp" "$STATE_FILE"; chmod 600 "$STATE_FILE"; }
