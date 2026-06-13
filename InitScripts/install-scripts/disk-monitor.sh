#!/bin/bash
# 磁盘空间监控 #

disk=(
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_disk-monitor.log"

# 安装磁盘监控依赖
printf "${NOTE} 正在安装 ${SKY_BLUE}磁盘监控${RESET} 软件包...\n"
for DISK in "${disk[@]}"; do
  install_package "$DISK" "$LOG"
done

# 创建磁盘监控脚本
printf "${NOTE} 正在创建 ${YELLOW}磁盘空间监控${RESET} 脚本...\n"

DISK_SCRIPT="$HOME/.config/hypr/scripts/disk-monitor.sh"
mkdir -p "$HOME/.config/hypr/scripts"

cat > "$DISK_SCRIPT" << 'EOF'
#!/bin/bash
# 磁盘空间监控脚本
# 监控磁盘使用情况并发送通知

# 配置
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
CHECK_INTERVAL=300  # 每 5 分钟检查一次

# 跟踪通知状态，避免重复提醒
declare -A NOTIFIED_WARNING
declare -A NOTIFIED_CRITICAL

while true; do
    # 获取所有已挂载设备的磁盘使用率
    df -h | grep '^/dev/' | while read -r line; do
        DEVICE=$(echo "$line" | awk '{print $1}')
        MOUNT=$(echo "$line" | awk '{print $6}')
        USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        
        # 跳过非数字的利用率
        if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        # 检查磁盘使用率
        if [ "$USAGE" -ge "$DISK_CRITICAL_THRESHOLD" ]; then
            if [ "${NOTIFIED_CRITICAL[$MOUNT]}" != "true" ]; then
                notify-send -u critical -i drive-harddisk "磁盘空间严重不足" "挂载点 $MOUNT 已使用 ${USAGE}%！\n设备: $DEVICE"
                NOTIFIED_CRITICAL[$MOUNT]="true"
                NOTIFIED_WARNING[$MOUNT]="true"
            fi
        elif [ "$USAGE" -ge "$DISK_WARNING_THRESHOLD" ]; then
            if [ "${NOTIFIED_WARNING[$MOUNT]}" != "true" ]; then
                notify-send -u normal -i drive-harddisk "磁盘空间不足" "挂载点 $MOUNT 已使用 ${USAGE}%\n设备: $DEVICE"
                NOTIFIED_WARNING[$MOUNT]="true"
            fi
        else
            # 使用率下降后重置通知标记
            if [ "$USAGE" -lt $((DISK_WARNING_THRESHOLD - 5)) ]; then
                NOTIFIED_WARNING[$MOUNT]="false"
                NOTIFIED_CRITICAL[$MOUNT]="false"
            fi
        fi
    done
    
    sleep "$CHECK_INTERVAL"
done
EOF

chmod +x "$DISK_SCRIPT"

printf "${OK} 磁盘监控脚本已创建在 ${YELLOW}$DISK_SCRIPT${RESET}\n"

# 创建 systemd 用户服务
printf "${NOTE} 正在创建 ${YELLOW}systemd 用户服务${RESET} 用于磁盘监控...\n"

SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/disk-monitor.service" << EOF
[Unit]
Description=磁盘空间监控
After=graphical-session.target

[Service]
Type=simple
ExecStart=$DISK_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

printf "${OK} systemd 服务已创建\n"

# 启用并启动服务
printf "${NOTE} 正在启用并启动 ${YELLOW}disk-monitor${RESET} 服务...\n"
systemctl --user daemon-reload
systemctl --user enable disk-monitor.service 2>&1 | tee -a "$LOG"
systemctl --user start disk-monitor.service 2>&1 | tee -a "$LOG"

printf "${OK} 磁盘监控服务现在正在运行！\n"
printf "${INFO} 您可以查看状态：${YELLOW}systemctl --user status disk-monitor${RESET}\n"
printf "${INFO} 查看磁盘使用情况：${YELLOW}df -h${RESET}\n"

printf "\n%.0s" {1..2}
