#!/usr/bin/env bash
set -euo pipefail

# Detect the expected YubiKey by its USB vendor and product IDs.
readonly VID=1050
readonly PID=0407

if [[ -t 1 && -z ${NO_COLOR:-} && ${TERM:-dumb} != dumb ]]; then
    green=$'\033[32m'
    red=$'\033[31m'
    reset=$'\033[0m'
else
    green='' red='' reset=''
fi

inserted=false

# Prefer lsusb when available. Some versions return nonzero for no matches.
if command -v lsusb >/dev/null 2>&1; then
    if result=$(lsusb -d "$VID:$PID" 2>/dev/null) && [[ -n $result ]]; then
        inserted=true
    fi
fi

# Linux sysfs also exposes USB IDs, even when lsusb is unavailable or fails.
if [[ $inserted == false ]]; then
    for device in /sys/bus/usb/devices/*; do
        [[ -r $device/idVendor && -r $device/idProduct ]] || continue
        read -r vendor < "$device/idVendor" || continue
        read -r product < "$device/idProduct" || continue
        if [[ ${vendor,,} == "$VID" && ${product,,} == "$PID" ]]; then
            inserted=true
            break
        fi
    done
fi

if [[ $inserted == true ]]; then
    printf '%sYubiKey is inserted.%s\n' "$green" "$reset"
    exit 0
fi

printf '%sYubiKey is not inserted.%s\n' "$red" "$reset"
exit 1
