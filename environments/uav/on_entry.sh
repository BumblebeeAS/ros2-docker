#!/bin/bash
set -e

# Refresh the linker cache after mounting Jetson driver libraries.
printf '%s\n' /usr/lib/aarch64-linux-gnu/tegra /usr/lib/aarch64-linux-gnu/nvidia \
    | sudo tee /etc/ld.so.conf.d/jetson-host.conf >/dev/null
sudo ldconfig
