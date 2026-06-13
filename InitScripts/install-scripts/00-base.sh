#!/bin/bash
# 安装 base-devel 和 archlinux-keyring #

base=( 
  base-devel
  archlinux-keyring
  findutils
)

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_base.log"

# 使用 pacman 安装主要组件
echo -e "\n正在安装 ${SKY_BLUE}base-devel${RESET} 和 ${SKY_BLUE}archlinux-keyring${RESET}..."

for PKG1 in "${base[@]}"; do
  echo "正在使用 pacman 安装 $PKG1 ..."
  install_package_pacman "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}
