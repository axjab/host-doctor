#!/usr/bin/env bash
set -euo pipefail

# YubiKey USB presence check (Yubico VID 1050, expected PID 0407).
# USB bus/device numbers change across reconnections.
readonly VID='1050'
readonly PID='0407'

if [[ -t 1 && -z ${NO_COLOR:-} && ${TERM:-dumb} != dumb ]]; then
    green=$'\033[32m'
    red=$'\033[31m'
    yellow=$'\033[33m'
    reset=$'\033[0m'
else
    green='' red='' yellow='' reset=''
fi

if ! command -v lsusb >/dev/null 2>&1; then
    printf '%sERROR%s: lsusb is missing. Install it: sudo apt install usbutils\n' "$red" "$reset" >&2
    exit 2
fi

# -d matches the exact USB vendor/product pair; avoid fragile text matching.
if ! output=$(lsusb -d "${VID}:${PID}"); then
    printf '%sERROR%s: lsusb failed to enumerate USB devices.\n' "$red" "$reset" >&2
    exit 2
fi

if [[ -n $output ]]; then
    printf '%sPASS%s: Expected YubiKey detected (USB %s:%s).\n' "$green" "$reset" "$VID" "$PID"
    printf '%s\n' "$output"
    exit 0
fi

printf '%sFAIL%s: Expected YubiKey not detected (USB %s:%s).\n' "$red" "$reset" "$VID" "$PID"
printf '%sINFO%s: Insert the key and retry. Other YubiKey models use different product IDs.\n' "$yellow" "$reset"
exit 1
