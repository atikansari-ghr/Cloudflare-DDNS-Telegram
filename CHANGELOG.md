# Changelog

## v4.1.0 — 2026-07-08
- Telegram sends now verify the API response, retry up to 3 times with backoff, and log the exact delivery error to the journal (previously failures were silently discarded).
- New systemd `OnFailure` hook: a crashed service triggers a 🚨 Telegram alert including recent journal lines (`notify-failure.sh` + `cloudflare-ddns-failure@.service`).
- Implemented the previously unused `VERIFY_DNS` option: after an update, records are re-resolved via 1.1.1.1 and a mismatch raises an alert (DNS-only records).

## v4.0.0 — 2026-07-07
- Added fallback IP providers.
- Added timeout tuning.
- Added systemd startup delay.
- Added upgrade.sh for existing installations.
