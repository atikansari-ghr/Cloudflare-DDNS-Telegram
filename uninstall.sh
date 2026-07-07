#!/usr/bin/env bash
set -euo pipefail
INSTALL_DIR="/opt/cloudflare-ddns-telegram"; [[ "${EUID}" -ne 0 ]] && { echo "Please run as root: sudo ./uninstall.sh"; exit 1; }
systemctl disable --now cloudflare-ddns.timer 2>/dev/null || true; systemctl disable --now cloudflare-ddns-status.timer 2>/dev/null || true; systemctl stop cloudflare-ddns.service 2>/dev/null || true; systemctl stop cloudflare-ddns-status.service 2>/dev/null || true
rm -f /etc/systemd/system/cloudflare-ddns.service /etc/systemd/system/cloudflare-ddns.timer /etc/systemd/system/cloudflare-ddns-status.service /etc/systemd/system/cloudflare-ddns-status.timer /etc/logrotate.d/cloudflare-ddns-telegram; systemctl daemon-reload
read -r -p "Remove installation directory $INSTALL_DIR? yes/no [no]: " r; [[ "${r:-no}" == yes ]] && rm -rf "$INSTALL_DIR"; echo "Uninstall complete."
