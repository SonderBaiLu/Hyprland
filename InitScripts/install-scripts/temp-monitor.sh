#!/bin/bash
# 温度监控 - CPU/GPU 温度警报 #
temp=(
  lm_sensors
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_temp-monitor.log"

# 安装温度监控软件包
printf "${NOTE} 正在安装 ${SKY_BLUE}温度监控${RESET} 软件包...\n"
for TEMP in "${temp[@]}"; do
  install_package "$TEMP" "$LOG"
done

# 检测传感器
printf "${NOTE} 正在检测 ${YELLOW}硬件传感器${RESET}...\n"
sudo sensors-detect --auto 2>&1 | tee -a "$LOG"

# 创建温度监控脚本
printf "${NOTE} 正在创建 ${YELLOW}温度监控${RESET} 脚本...\n"

TEMP_SCRIPT="$HOME/.config/hypr/scripts/temp-monitor.sh"
mkdir -p "$HOME/.config/hypr/scripts"

cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
# 温度监控脚本
# 监控 CPU 和 GPU 温度并发送警报

# 配置
CPU_TEMP_WARNING=75
CPU_TEMP_CRITICAL=85
GPU_TEMP_WARNING=75
GPU_TEMP_CRITICAL=85
CHECK_INTERVAL=30  # 每 30 秒检查一次

# 通知状态跟踪，避免重复提醒
NOTIFIED_CPU_WARN=false
NOTIFIED_CPU_CRIT=false
NOTIFIED_GPU_WARN=false
NOTIFIED_GPU_CRIT=false

while true; do
    # 获取 CPU 温度（所有核心的平均值）
    CPU_TEMP=$(sensors | grep -i 'Package id 0:\|Tdie:' | awk '{print $4}' | sed 's/+//;s/°C//' | head -1)
    
    # 如果找不到 Package id，尝试其他方法
    if [ -z "$CPU_TEMP" ]; then
        CPU_TEMP=$(sensors | grep -i 'Core 0:' | awk '{print $3}' | sed 's/+//;s/°C//' | head -1)
    fi
    
    # 获取 GPU 温度（如果可用）
    GPU_TEMP=$(sensors | grep -i 'edge:\|temp1:' | awk '{print $2}' | sed 's/+//;s/°C//' | head -1)
    
    # 检查 CPU 温度
    if [ -n "$CPU_TEMP" ]; then
        CPU_TEMP_INT=${CPU_TEMP%.*}
        
        if [ "$CPU_TEMP_INT" -ge "$CPU_TEMP_CRITICAL" ]; then
            if [ "$NOTIFIED_CPU_CRIT" = false ]; then
                notify-send -u critical -i temperature-high "CPU 温度严重过高" "CPU 温度已达 ${CPU_TEMP}°C！系统可能降频或关机。"
                NOTIFIED_CPU_CRIT=true
                NOTIFIED_CPU_WARN=true
            fi
        elif [ "$CPU_TEMP_INT" -ge "$CPU_TEMP_WARNING" ]; then
            if [ "$NOTIFIED_CPU_WARN" = false ]; then
                notify-send -u normal -i temperature-normal "CPU 温度偏高" "CPU 温度当前为 ${CPU_TEMP}°C"
                NOTIFIED_CPU_WARN=true
            fi
        else
            NOTIFIED_CPU_WARN=false
            NOTIFIED_CPU_CRIT=false
        fi
    fi
    
    # 检查 GPU 温度
    if [ -n "$GPU_TEMP" ]; then
        GPU_TEMP_INT=${GPU_TEMP%.*}
        
        if [ "$GPU_TEMP_INT" -ge "$GPU_TEMP_CRITICAL" ]; then
            if [ "$NOTIFIED_GPU_CRIT" = false ]; then
                notify-send -u critical -i temperature-high "GPU 温度严重过高" "GPU 温度已达 ${GPU_TEMP}°C！"
                NOTIFIED_GPU_CRIT=true
                NOTIFIED_GPU_WARN=true
            fi
        elif [ "$GPU_TEMP_INT" -ge "$GPU_TEMP_WARNING" ]; then
            if [ "$NOTIFIED_GPU_WARN" = false ]; then
                notify-send -u normal -i temperature-normal "GPU 温度偏高" "GPU 温度当前为 ${GPU_TEMP}°C"
                NOTIFIED_GPU_WARN=true
            fi
        else
            NOTIFIED_GPU_WARN=false
            NOTIFIED_GPU_CRIT=false
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done
EOF

chmod +x "$TEMP_SCRIPT"

printf "${OK} 温度监控脚本已创建在 ${YELLOW}$TEMP_SCRIPT${RESET}\n"

# 创建 systemd 用户服务
printf "${NOTE} 正在为温度监控创建 ${YELLOW}systemd 用户服务${RESET}...\n"

SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/temp-monitor.service" << EOF
[Unit]
Description=温度监控
After=graphical-session.target

[Service]
Type=simple
ExecStart=$TEMP_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

printf "${OK} systemd 服务已创建\n"

# 启用并启动服务
printf "${NOTE} 正在启用并启动 ${YELLOW}temp-monitor${RESET} 服务...\n"
systemctl --user daemon-reload
systemctl --user enable temp-monitor.service 2>&1 | tee -a "$LOG"
systemctl --user start temp-monitor.service 2>&1 | tee -a "$LOG"

printf "${OK} 温度监控服务现在正在运行！\n"
printf "${INFO} 您可以查看状态：${YELLOW}systemctl --user status temp-monitor${RESET}\n"
printf "${INFO} 查看温度信息：${YELLOW}sensors${RESET}\n"

printf "\n%.0s" {1..2}
