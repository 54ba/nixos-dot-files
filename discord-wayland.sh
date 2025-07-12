#!/usr/bin/env bash
# Discord Wayland Launcher Script
# This script runs Discord with proper Wayland support and optimizations

# Set environment variables
export XDG_SESSION_TYPE="wayland"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export NIXOS_OZONE_WL="1"
export ELECTRON_OZONE_PLATFORM_HINT="wayland"

# Run Discord with proper Wayland flags
exec /run/current-system/sw/bin/discord \
  --enable-features=UseOzonePlatform,WaylandWindowDecorations \
  --ozone-platform=wayland \
  --no-sandbox \
  --disable-gpu-sandbox \
  --disable-dev-shm-usage \
  --no-zygote \
  --single-process \
  --disable-features=VizDisplayCompositor,zygote \
  "$@"

