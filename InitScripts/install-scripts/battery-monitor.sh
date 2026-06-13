#!/bin/bash
# 电池监控与低电量通知 #

battery=(
  acpi
  libnotify
)

## 警告：如果您不知道自己在做什么，请勿编辑此行之后的内容！ ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 将工作目录切换到脚本的父目录
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} 无法切换到目录 $PARENT_DIR"; exit 1; }

# 引入全局函数脚本
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "引入 Global_functions.sh 失败"
  exit 1
fi

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/install-$(date +%d-%H%M%S)_battery-monitor.log"

# 电池监控
printf "${NOTE} 正在安装 ${SKY_BLUE}电池监控${RESET} 软件包...\n"
for BAT in "${battery[@]}"; do
  install_package "$BAT" "$LOG"
done

# 创建电池监控脚本
printf "${NOTE} 正在创建 ${YELLOW}电池监控${RESET} 脚本...\n"

BATTERY_SCRIPT="$HOME/.config/hypr/scripts/battery-monitor.sh"
mkdir -p "$HOME/.config/hypr/scripts"

cat > "$BATTERY_SCRIPT" << 'EOF'
#!/bin/bash
# 低电量通知脚本
# 监控电池电量并发送通知

# 配置
LOW_BATTERY_THRESHOLD=20
CRITICAL_BATTERY_THRESHOLD=10
CHECK_INTERVAL=60  # 每 60 秒检查一次

# 跟踪通知状态以避免频繁提醒
NOTIFIED_LOW=false
NOTIFIED_CRITICAL=false

while true; do
    # 获取电池百分比
    BATTERY_LEVEL=$(acpi -b | grep -P -o '[0-9]+(?=%)')
    BATTERY_STATUS=$(acpi -b | grep -o 'Discharging\|Charging\|Full')
    
    # 仅当放电时发送通知
    if [ "$BATTERY_STATUS" = "Discharging" ]; then
        if [ "$BATTERY_LEVEL" -le "$CRITICAL_BATTERY_THRESHOLD" ] && [ "$NOTIFIED_CRITICAL" = false ]; then
            notify-send -u critical -i battery-caution "严重低电量" "电池电量仅为 ${BATTERY_LEVEL}%！请立即连接充电器。"
            NOTIFIED_CRITICAL=true
            NOTIFIED_LOW=true
        elif [ "$BATTERY_LEVEL" -le "$LOW_BATTERY_THRESHOLD" ] && [ "$NOTIFIED_LOW" = false ]; then
            notify-send -u normal -i battery-low "低电量" "电池电量为 ${BATTERY_LEVEL}%。建议连接充电器。"
            NOTIFIED_LOW=true
        fi
    else
        # 充电或充满时重置通知标志
        NOTIFIED_LOW=false
        NOTIFIED_CRITICAL=false
    fi
    
    sleep "$CHECK_INTERVAL"
done
EOF

chmod +x "$BATTERY_SCRIPT"

printf "${OK} 电池监控脚本已创建在 ${YELLOW}$BATTERY_SCRIPT${RESET}\n"

# 创建 systemd 用户服务
printf "${NOTE} 正在创建 ${YELLOW}systemd 用户服务${RESET} 用于电池监控...\n"

SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/battery-monitor.service" << EOF
[Unit]
Description=电池电量监控
After=graphical-session.target

[Service]
Type=simple
ExecStart=$BATTERY_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

printf "${OK} systemd 服务已创建\n"

# 启用并启动服务
printf "${NOTE} 正在启用并启动 ${YELLOW}battery-monitor${RESET} 服务...\n"
systemctl --user daemon-reload
systemctl --user enable battery-monitor.service 2>&1 | tee -a "$LOG"
systemctl --user start battery-monitor.service 2>&1 | tee -a "$LOG"

printf "${OK} 电池监控服务现在正在运行！\n"
printf "${INFO} 您可以查看状态：${YELLOW}systemctl --user status battery-monitor${RESET}\n"
printf "${INFO} 停止：${YELLOW}systemctl --user stop battery-monitor${RESET}\n"
printf "${INFO} 禁用：${YELLOW}systemctl --user disable battery-monitor${RESET}\n"

printf "\n%.0s" {1..2}
