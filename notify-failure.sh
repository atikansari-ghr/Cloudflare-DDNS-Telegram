#!/usr/bin/env bash
# Fired by systemd OnFailure= when a cloudflare-ddns unit crashes.
# Deliberately no set -e: this is the last line of defense and must try to send no matter what.
set -uo pipefail
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$INSTALL_DIR/config/config.env"
source "$INSTALL_DIR/logger.sh"
source "$INSTALL_DIR/telegram.sh"
unit="${1:-unknown-unit}"
SERVER_NAME="$(hostname -s 2>/dev/null || hostname)"
recent="$(journalctl -u "$unit" -n 5 --no-pager -o cat 2>/dev/null | tail -c 700 || true)"
recent="$(html_escape "${recent:-no journal output available}")"
log_msg ERROR "Unit ${unit} failed; sending Telegram failure alert."
send_telegram "🚨 <b>Cloudflare DDNS Service Failed</b>

<b>Unit:</b> ${unit}
<b>Server:</b> ${SERVER_NAME}
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S %Z')

<b>Recent log:</b>
<pre>${recent}</pre>"
