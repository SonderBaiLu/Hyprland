#!/bin/bash
# 华硕 ROG 笔记本专用 #

rog=(
    power-profiles-daemon
    asusctl
    supergfxctl
    rog-control-center
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_rog.log"

### 安装华硕 ROG 笔记本软件 ###

printf " 正在安装 ${SKY_BLUE}华硕 ROG 软件包${RESET}...\n"
for ASUS in "${rog[@]}"; do
install_package  "$ASUS" "$LOG"
done

printf " 正在激活 ROG 服务...\n"
sudo systemctl enable supergfxd 2>&1 | tee -a "$LOG"

printf " 正在启用 power-profiles-daemon...\n"
sudo systemctl enable power-profiles-daemon 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
