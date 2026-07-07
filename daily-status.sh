#!/usr/bin/env bash
set -euo pipefail
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$INSTALL_DIR/config/config.env"; source "$INSTALL_DIR/logger.sh"; source "$INSTALL_DIR/telegram.sh"; source "$INSTALL_DIR/utils.sh"; source "$INSTALL_DIR/cloudflare-api.sh"
SERVER_NAME="$(hostname -s 2>/dev/null || hostname)"; [[ "${DAILY_STATUS_ENABLED:-no}" != yes ]] && { log_msg INFO "Daily status is disabled."; exit 0; }; [[ "${TELEGRAM_ENABLED:-no}" != yes ]] && { log_msg INFO "Telegram is disabled."; exit 0; }
ipv4="$(get_public_ipv4)"; is_valid_ipv4 "$ipv4" || ipv4="not-detected"; ipv6="$(get_public_ipv6)"; is_valid_ipv6 "$ipv6" || ipv6="not-detected"; lines=""; overall="OK"
while IFS='|' read -r zone record type ttl proxied; do [[ -z "${zone:-}" || "$zone" =~ ^# ]] && continue; zone="$(trim_spaces "$zone")"; record="$(trim_spaces "$record")"; type="$(trim_spaces "${type:-A}")"; zid="$(get_zone_id "$zone")"; [[ -z "$zid" ]] && { lines+=$'
'"❌ $record — zone not found"; overall="ISSUE"; continue; }; check(){ rid="$(get_record_id "$zid" "$record" "$1")"; [[ -z "$rid" ]] && { lines+=$'
'"❌ $record $1 — record missing"; overall="ISSUE"; return; }; cfip="$(get_record_content "$zid" "$rid")"; if [[ "$2" == not-detected ]]; then lines+=$'
'"⚠️ $record $1 — public IP not detected, Cloudflare: $cfip"; overall="ISSUE"; elif [[ "$cfip" == "$2" ]]; then lines+=$'
'"✅ $record $1 — $cfip"; else lines+=$'
'"⚠️ $record $1 — Cloudflare: $cfip, Current: $2"; overall="ISSUE"; fi; }; case "$type" in A) check A "$ipv4";; AAAA) check AAAA "$ipv6";; BOTH) check A "$ipv4"; check AAAA "$ipv6";; esac; done < "$RECORDS_FILE"
send_telegram "📡 <b>Daily Cloudflare DDNS IP Status</b>

<b>Status:</b> ${overall}
<b>Server:</b> ${SERVER_NAME}
<b>Detected IPv4:</b> ${ipv4}
<b>Detected IPv6:</b> ${ipv6}
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S %Z')

<b>Records:</b>${lines}"; log_msg INFO "Daily IP status sent. Status: ${overall}"
