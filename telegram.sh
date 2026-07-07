#!/usr/bin/env bash
send_telegram(){ local m="$1"; [[ "${TELEGRAM_ENABLED:-no}" != "yes" ]] && return 0; [[ -z "${BOT_TOKEN:-}" || -z "${CHAT_ID:-}" ]] && return 0; curl -sS --connect-timeout 10 --max-time 25 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" -d "parse_mode=HTML" --data-urlencode "text=${m}" >/dev/null || true; }
telegram_updated(){ send_telegram "🟢 <b>Cloudflare DDNS Updated</b>

<b>Record:</b> $1
<b>Type:</b> $2
<b>Old IP:</b> $3
<b>New IP:</b> $4
<b>Server:</b> $5
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S %Z')"; }
telegram_error(){ send_telegram "🔴 <b>Cloudflare DDNS Error</b>

<b>Error:</b> $1
<b>Server:</b> $2
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S %Z')"; }
telegram_no_change(){ [[ "${SEND_NO_CHANGE:-no}" != "yes" ]] && return 0; send_telegram "ℹ️ <b>Cloudflare DDNS No Change</b>

<b>Record:</b> $1
<b>Type:</b> $2
<b>IP:</b> $3
<b>Server:</b> $4
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S %Z')"; }
telegram_startup(){ [[ "${SEND_STARTUP:-yes}" != "yes" ]] && return 0; send_telegram "✅ <b>Cloudflare DDNS Started</b>

<b>Server:</b> $1
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S %Z')"; }
