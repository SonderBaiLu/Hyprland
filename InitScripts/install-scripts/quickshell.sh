#!/bin/bash
# quickshell - 用于桌面概览，替代 AGS

if [[ $USE_PRESET = [Yy] ]]; then
  source ./preset.sh
fi

quick=(
    qt6-5compat
    quickshell
)

## 警告：如果您不知道自己在做什么，请勿编辑此行之后的内容！ ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 将工作目录切换到脚本的父目录
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
  echo "${ERROR} 无法切换到目录 $PARENT_DIR"
  exit 1
}

# 引入全局函数脚本
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "引入 Global_functions.sh 失败"
  exit 1
fi

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/install-$(date +%d-%H%M%S)_quick.log"

# 安装主要组件
printf "\n%s - 正在安装 ${SKY_BLUE}Quick Shell ${RESET} 用于桌面概览 \n" "${NOTE}"

for PKG1 in "${quick[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}
