#!/usr/bin/env bash
log_msg(){ local l="$1" m="$2" t; t="$(date '+%Y-%m-%d %H:%M:%S %Z')"; echo "[$t] [$l] $m"; if [[ "${LOGGING:-yes}" == "yes" && -n "${LOG_FILE:-}" ]]; then mkdir -p "$(dirname "$LOG_FILE")"; echo "[$t] [$l] $m" >> "$LOG_FILE"; fi; }
