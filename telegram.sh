#!/usr/bin/env bash
html_escape(){ local s="$1"; s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; echo "$s"; }
send_telegram(){
  local m="$1" attempt response ok detail
  [[ "${TELEGRAM_ENABLED:-no}" != "yes" ]] && return 0
  if [[ -z "${BOT_TOKEN:-}" || -z "${CHAT_ID:-}" ]]; then log_msg WARN "Telegram is enabled but BOT_TOKEN or CHAT_ID is empty; alert not sent."; return 0; fi
  for attempt in 1 2 3; do
    response="$(curl -sS --connect-timeout 10 --max-time 25 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" -d "parse_mode=HTML" --data-urlencode "text=${m}" 2>&1)" || response=""
    ok="$(echo "$response"|jq -r '.ok' 2>/dev/null || true)"
    [[ "$ok" == "true" || "$response" == *'"ok":true'* ]] && return 0
    detail="$(echo "$response"|jq -r '"HTTP \(.error_code): \(.description)"' 2>/dev/null || true)"
    [[ -z "$detail" || "$detail" == *null* ]] && detail="${response:-no response (network error)}"
    log_msg WARN "Telegram send failed (attempt ${attempt}/3): ${detail:0:300}"
    [[ "$attempt" -lt 3 ]] && sleep $((attempt * 3))
  done
  log_msg ERROR "Telegram alert NOT delivered after 3 attempts. Check BOT_TOKEN/CHAT_ID and network."
  return 0
}
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
