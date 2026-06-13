#!/bin/bash
# 设置 Index 为默认文件管理器 #
## 警告：如果您不清楚下面代码的作用，请勿编辑！ ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 切换到脚本所在目录的上一级
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} 无法切换到目录 $PARENT_DIR"; exit 1; }

# 加载全局函数脚本
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "加载 Global_functions.sh 失败"
  exit 1
fi

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/install-$(date +%d-%H%M%S)_index-default.log"

printf "${INFO} 正在将 ${SKY_BLUE}Index${RESET} 设为默认文件管理器...\n"

xdg-mime default org.kde.index.desktop inode/directory
xdg-mime default org.kde.index.desktop application/x-wayland-gnome-saved-search
echo "${OK} ${MAGENTA}Index${RESET} 已成功设为默认文件管理器。" | tee -a "$LOG"

printf "\n%.0s" {1..2}
