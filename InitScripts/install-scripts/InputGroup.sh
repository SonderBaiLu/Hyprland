#!/bin/bash
# 将用户添加到 input 组 #

## 警告：如果不清楚自己在做什么，请不要编辑此行以下的内容！ ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 将工作目录切换到脚本所在目录的上级目录
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} 无法切换到目录 $PARENT_DIR"; exit 1; }

# 加载全局函数脚本
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "加载 Global_functions.sh 失败"
  exit 1
fi

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/install-$(date +%d-%H%M%S)_input.log"

# 检查 'input' 组是否存在
if grep -q '^input:' /etc/group; then
    echo "${OK} ${MAGENTA}input${RESET} 组已存在。"
else
    echo "${NOTE} ${MAGENTA}input${RESET} 组不存在。正在创建 ${MAGENTA}input${RESET} 组..."
    sudo groupadd input
    echo "${MAGENTA}input${RESET} 组已创建" >> "$LOG"
fi

# 将用户添加到 'input' 组
sudo usermod -aG input "$(whoami)"
echo "${OK} 已将 ${YELLOW}用户${RESET} 添加到 ${MAGENTA}input${RESET} 组。更改将在您注销并重新登录后生效。" >> "$LOG"

printf "\n%.0s" {1..2}
