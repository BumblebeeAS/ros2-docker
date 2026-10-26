#!/usr/bin/env bash
set -euo pipefail

if [[ -e /.dockerenv || ! -f /etc/nv_tegra_release ]]; then
    printf '%s\n' 'Run this installer on the Jetson host, outside Docker.' >&2
    exit 1
fi

if ! grep -q '^# R39 .*REVISION: 2\.' /etc/nv_tegra_release; then
    printf '%s\n' 'This IMX219 override is intended for JetPack 7.2 (L4T R39.2.x).'
    exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SOURCE="$SCRIPT_DIR/camera_overrides.isp"
SETTINGS_DIR=/var/nvidia/nvcam/settings
TARGET="$SETTINGS_DIR/camera_overrides.isp"

if [[ ! -d "$SETTINGS_DIR" ]]; then
    printf 'Camera settings directory is missing: %s\n' "$SETTINGS_DIR" >&2
    exit 1
fi

if sudo cmp -s "$SOURCE" "$TARGET"; then
    sudo chown root:root "$TARGET"
    sudo chmod 664 "$TARGET"
    printf '%s\n' 'The IMX219 ISP override is already installed.'
    exit 0
fi

if sudo test -e "$TARGET"; then
    BACKUP_DIR=$(sudo mktemp -d "$SETTINGS_DIR/isp-backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")
    sudo cp -a "$TARGET" "$BACKUP_DIR/"
    printf 'Previous ISP override saved to %s\n' "$BACKUP_DIR"
fi

sudo install -o root -g root -m 664 "$SOURCE" "$TARGET"
printf '%s\n' 'Installed the IMX219 ISP override. Reboot to apply it.'
