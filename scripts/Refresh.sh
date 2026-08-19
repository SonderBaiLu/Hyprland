#!/usr/bin/env bash
# 仅保留基础重载与 Noctalia 刷新
killall -SIGUSR1 kitty 2>/dev/null || true

# 刷新 Noctalia
if command -v noctalia-shell >/dev/null 2>&1; then
    noctalia-shell ipc reload >/dev/null 2>&1 || true
fi

# 重载 Hyprland
hyprctl reload >/dev/null 2>&1 || true
