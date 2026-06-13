#!/bin/bash
# Index 文件管理器 #
# 需要安装的 Index 文件管理器相关软件包列表
index=(
  index-fm
)
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_index.log"

# 安装 Index 文件管理器
printf "${INFO} 正在安装 ${SKY_BLUE}Index${RESET} 文件管理器软件包...\n"
for INDEX_PKG in "${index[@]}"; do
  install_package "$INDEX_PKG" "$LOG"
done

printf "\n%.0s" {1..1}

# 检查并复制 Index 文件管理器的配置文件
CONFIG_DIR="$HOME/.config/index-fm"
if [ -d "$CONFIG_DIR" ]; then
  echo -e "${NOTE} 已找到 ${MAGENTA}Index${RESET} 的配置，无需复制。" 2>&1 | tee -a "$LOG"
else
  echo -e "${NOTE} ${YELLOW}Index${RESET} 的配置未找到，正在从 assets 复制..." 2>&1 | tee -a "$LOG"
  # 如果 assets 目录下没有 index-fm 的配置，此行会失败，但不会中断脚本
  if cp -r assets/index-fm "$HOME/.config/" 2>/dev/null; then
    echo "${OK} 复制 Index 配置完成！" 2>&1 | tee -a "$LOG"
  else
    echo "${WARN} 未找到预置的 Index 配置文件（assets/index-fm），将使用默认配置。 此为正常 无视它" 2>&1 | tee -a "$LOG"
  fi
fi
printf "\n%.0s" {1..2}
