#!/bin/bash
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

# 检查 Hyprland-Dots 是否已存在
printf "${NOTE} 正在克隆并安装 ${SKY_BLUE}KooL 的 Hyprland Dots${RESET}....\n"

if [ -d Hyprland-Dots ]; then
  cd Hyprland-Dots
  git stash && git pull
  chmod +x copy.sh
  ./copy.sh 
else
  if git clone --depth=1 https://github.com/SonderBaiLu/Hyprland.git; then
    cd Hyprland-Dots || exit 1
    chmod +x copy.sh
    ./copy.sh 
  else
    echo -e "$ERROR 无法下载 ${YELLOW}KooL 的 Hyprland-Dots${RESET}，请检查网络连接"
  fi
fi

printf "\n%.0s" {1..2}
