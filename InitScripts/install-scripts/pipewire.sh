#!/bin/bash
# Pipewire 和 Pipewire 音频相关软件 #

pipewire=(
    pipewire
    wireplumber
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    sof-firmware
)

# 添加此项是因为有报告称脚本未安装该包
# 这里基本上就是强制重新安装
pipewire_2=(
    pipewire-pulse
)

############## 警告：如果您不知道自己在做什么，请勿编辑此行之后的内容！ ##############
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 将工作目录切换到脚本的父目录
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} 无法切换到目录 $PARENT_DIR"; exit 1; }

# 引入全局函数脚本
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pipewire.log"

# 禁用 pulseaudio 以避免冲突，并记录输出
echo -e "${NOTE} 正在禁用 pulseaudio 以避免冲突..."
systemctl --user disable --now pulseaudio.socket pulseaudio.service >> "$LOG" 2>&1 || true

# Pipewire
echo -e "${NOTE} 正在安装 ${SKY_BLUE}Pipewire${RESET} 软件包..."
for PIPEWIRE in "${pipewire[@]}"; do
    install_package "$PIPEWIRE" "$LOG"
done

for PIPEWIRE2 in "${pipewire_2[@]}"; do
    install_package_pacman "$PIPEWIRE" "$LOG"
done

echo -e "${NOTE} 正在启用 Pipewire 服务..."
# 将 systemctl 输出重定向到日志文件
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>&1 | tee -a "$LOG"
systemctl --user enable --now pipewire.service 2>&1 | tee -a "$LOG"

echo -e "\n${OK} Pipewire 安装及服务配置已完成！" 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
