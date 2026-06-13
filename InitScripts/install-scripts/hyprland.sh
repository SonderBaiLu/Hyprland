#!/bin/bash
# 主要的 Hyprland 软件包 #

hypr_eco=(
  hypridle
  hyprlock
)

hypr=(
  hyprland
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland.log"

# 检查 Hyprland 是否已安装
if command -v Hyprland >/dev/null 2>&1; then
  printf "$NOTE - ${YELLOW} Hyprland 已安装。${RESET} 无需操作。\n"
else
  printf "$INFO - 未找到 Hyprland。${SKY_BLUE} 正在安装 Hyprland...${RESET}\n"
  for HYPRLAND in "${hypr[@]}"; do
    install_package "$HYPRLAND" "$LOG"
  done
fi

# 安装 Hyprland 生态的其他软件包
printf "${NOTE} - 正在安装 ${SKY_BLUE}其他 Hyprland 生态软件包${RESET} .......\n"
for HYPR in "${hypr_eco[@]}"; do
  if ! command -v "$HYPR" >/dev/null 2>&1; then
    printf "$INFO - 未找到 ${YELLOW}$HYPR${RESET}。正在安装 ${YELLOW}$HYPR...${RESET}\n"
    install_package "$HYPR" "$LOG"
  else
    printf "$NOTE - ${YELLOW} $HYPR 已安装。${RESET} 无需操作。\n"
  fi
done

printf "\n%.0s" {1..2}
