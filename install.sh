#!/usr/bin/env bash
set -euo pipefail
INSTALL_DIR="/opt/cloudflare-ddns-telegram"; CONFIG_FILE="$INSTALL_DIR/config/records.conf"; ENV_FILE="$INSTALL_DIR/config/config.env"
[[ "${EUID}" -ne 0 ]] && { echo "Please run as root: sudo ./install.sh"; exit 1; }
req(){ local p="$1" v=""; while [[ -z "$v" ]]; do read -r -p "$p: " v; done; echo "$v"; }
def(){ local p="$1" d="$2" v=""; read -r -p "$p [$d]: " v; echo "${v:-$d}"; }
apt update; apt install -y curl jq dnsutils ca-certificates logrotate
mkdir -p "$INSTALL_DIR"/{logs,backup,config}; cp update-ddns.sh telegram.sh logger.sh cloudflare-api.sh utils.sh daily-status.sh upgrade.sh "$INSTALL_DIR/"; chmod +x "$INSTALL_DIR"/*.sh
API_TOKEN=$(req "Cloudflare API Token"); ZONE_NAME=$(req "Cloudflare Zone Name, example: example.com"); DNS_RECORDS=$(req "DNS hostname(s), comma-separated"); RECORD_TYPE=$(def "DNS record type: A, AAAA, or BOTH" "A"); TTL=$(def "Cloudflare TTL" "120"); PROXIED=$(def "Cloudflare proxy enabled? true/false" "false"); TELEGRAM_ENABLED=$(def "Enable Telegram notifications? yes/no" "yes"); if [[ "$TELEGRAM_ENABLED" == yes ]]; then BOT_TOKEN=$(req "Telegram Bot Token"); CHAT_ID=$(req "Telegram Chat ID"); else BOT_TOKEN=""; CHAT_ID=""; fi; DAILY_STATUS_ENABLED=$(def "Send daily Telegram IP status report? yes/no" "yes"); DAILY_STATUS_TIME=$(def "Daily status time, HH:MM" "09:00"); INTERVAL=$(def "DDNS check interval in minutes" "5"); VERIFY_DNS=$(def "Verify DNS after update? yes/no" "yes"); SEND_NO_CHANGE=$(def "Send Telegram when there is no IP change? yes/no" "no"); SEND_STARTUP=$(def "Send Telegram after install/test run? yes/no" "yes"); LOGGING=$(def "Enable file logging? yes/no" "yes")
cat > "$ENV_FILE" <<EOF
API_TOKEN="$API_TOKEN"
TELEGRAM_ENABLED="$TELEGRAM_ENABLED"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
SEND_NO_CHANGE="$SEND_NO_CHANGE"
SEND_STARTUP="$SEND_STARTUP"
DAILY_STATUS_ENABLED="$DAILY_STATUS_ENABLED"
DAILY_STATUS_TIME="$DAILY_STATUS_TIME"
VERIFY_DNS="$VERIFY_DNS"
LOGGING="$LOGGING"
IPV4_PROVIDER="https://api.ipify.org"
IPV6_PROVIDER="https://api64.ipify.org"
LOG_FILE="$INSTALL_DIR/logs/cloudflare-ddns.log"
STATE_FILE="$INSTALL_DIR/config/ip-state.json"
RECORDS_FILE="$CONFIG_FILE"
EOF
cat > "$CONFIG_FILE" <<EOF
# zone_name|record_name|record_type|ttl|proxied
EOF
IFS=',' read -ra arr <<< "$DNS_RECORDS"; for r in "${arr[@]}"; do r="$(echo "$r"|xargs)"; [[ -n "$r" ]] && echo "${ZONE_NAME}|${r}|${RECORD_TYPE}|${TTL}|${PROXIED}" >> "$CONFIG_FILE"; done; chmod 600 "$ENV_FILE" "$CONFIG_FILE"
cp systemd/cloudflare-ddns.service /etc/systemd/system/cloudflare-ddns.service; cp systemd/cloudflare-ddns.timer /etc/systemd/system/cloudflare-ddns.timer; cp systemd/cloudflare-ddns-status.service /etc/systemd/system/cloudflare-ddns-status.service; cp systemd/cloudflare-ddns-status.timer /etc/systemd/system/cloudflare-ddns-status.timer; cp systemd/cloudflare-ddns.logrotate /etc/logrotate.d/cloudflare-ddns-telegram; sed -i "s|__INSTALL_DIR__|$INSTALL_DIR|g" /etc/systemd/system/cloudflare-ddns.service /etc/systemd/system/cloudflare-ddns-status.service; sed -i "s|OnUnitActiveSec=.*|OnUnitActiveSec=${INTERVAL}min|g" /etc/systemd/system/cloudflare-ddns.timer; h="${DAILY_STATUS_TIME%%:*}"; m="${DAILY_STATUS_TIME##*:}"; sed -i "s|OnCalendar=.*|OnCalendar=*-*-* ${h}:${m}:00|g" /etc/systemd/system/cloudflare-ddns-status.timer; systemctl daemon-reload; systemctl enable --now cloudflare-ddns.timer; [[ "$DAILY_STATUS_ENABLED" == yes ]] && systemctl enable --now cloudflare-ddns-status.timer; "$INSTALL_DIR/update-ddns.sh" --startup || true; echo "Installation complete."
