#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET_SCRIPT="$HOME/.local/bin/ros2-docker"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ros-docker"

if [[ $# -ne 0 ]]; then
    printf "Usage: %s\n" "$0" >&2
    printf "Select an environment afterward with: ros2-docker use <environment>\n" >&2
    exit 1
fi

mkdir -p "$(dirname "$TARGET_SCRIPT")" "$CONFIG_DIR"
ln -sf "$ROOT/ros2-docker" "$TARGET_SCRIPT"
printf "%s" "$ROOT" > "$CONFIG_DIR/project_root"

printf "ros2-docker installed at %s\n" "$TARGET_SCRIPT"
if [[ ":$PATH:" != *":$(dirname "$TARGET_SCRIPT"):"* ]]; then
    printf "Add %s to PATH before invoking ros2-docker directly.\n" "$(dirname "$TARGET_SCRIPT")"
fi
