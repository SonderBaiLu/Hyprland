#!/bin/bash
# fish 及常用插件 #
# 基础 fish 相关软件包（可根据需要增减）
fish_pkg=(
  fish
  fisher          # fish 插件管理器
  lsd             # 现代 ls 替代
  mercurial       # 版本控制工具（可选）
)

# 额外工具包
fish_pkg2=(
  fzf             # 模糊查找器
)

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_fish.log"

# 安装核心 fish 软件包
printf "\n%s - 正在安装 ${SKY_BLUE}fish 及基础包${RESET} .... \n" "${NOTE}"
for FISH_PKG in "${fish_pkg[@]}"; do
  install_package "$FISH_PKG" "$LOG"
done 

# 安装 fish 插件管理器及常用插件（若 fish 可用）
if command -v fish >/dev/null; then
  printf "${NOTE} 正在安装 ${SKY_BLUE}fish 插件${RESET} ...\n"

  # 确保 fisher 已安装（通过包管理器安装后应可用）
  if command -v fisher >/dev/null; then
    # 安装自动建议插件（语法高亮 fish 自带，无需额外安装）
    fish -c "fisher install jorgebucaran/fish-autosuggestions" 2>&1 | tee -a "$LOG"
  else
    echo "${WARN} 未找到 fisher，尝试手动安装..." | tee -a "$LOG"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>&1 | tee -a "$LOG"
    fish -c "fisher install jorgebucaran/fish-autosuggestions" 2>&1 | tee -a "$LOG"
  fi

  # 备份已有的 fish 配置文件
  if [ -f "$HOME/.config/fish/config.fish" ]; then
      cp -b "$HOME/.config/fish/config.fish" "$HOME/.config/fish/config.fish-backup" || true
      echo "${NOTE} 已备份旧的 fish 配置。" | tee -a "$LOG"
  fi

  # 复制预配置的 fish 配置文件（假设 assets 中有对应的结构）
  mkdir -p "$HOME/.config/fish"
  if [ -f "assets/config.fish" ]; then
    cp "assets/config.fish" "$HOME/.config/fish/config.fish"
    echo "${OK} 已复制预置的 config.fish。" | tee -a "$LOG"
  else
    echo "${WARN} 未找到 assets/config.fish，将使用 fish 默认配置。 未找到为正常" | tee -a "$LOG"
  fi

  # 如果有额外的函数或补全文件，一并复制
  if [ -d "assets/fish" ]; then
    cp -r assets/fish/* "$HOME/.config/fish/" 2>&1 | tee -a "$LOG"
    echo "${OK} 已复制额外的 fish 配置文件。" | tee -a "$LOG"
  fi

  # 检查当前 shell 是否为 fish，若不是则尝试切换
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "fish" ]; then
    printf "${NOTE} 正在将默认 shell 切换为 ${MAGENTA}fish${RESET}..."
    printf "\n%.0s" {1..2}

    # 循环直到 chsh 成功
    while ! chsh -s "$(command -v fish)"; do
      echo "${ERROR} 认证失败，请输入正确的密码。" 2>&1 | tee -a "$LOG"
      sleep 1
    done

    printf "${INFO} Shell 已成功切换至 ${MAGENTA}fish${RESET}" 2>&1 | tee -a "$LOG"
  else
    echo "${NOTE} 当前 Shell 已经是 ${MAGENTA}fish${RESET}。"
  fi
else
  echo "${ERROR} 未检测到 fish，请检查安装是否成功。" | tee -a "$LOG"
fi

# 安装额外工具 fzf
printf "\n%s - 正在安装 ${SKY_BLUE}fzf${RESET} .... \n" "${NOTE}"
for FZF_PKG in "${fish_pkg2[@]}"; do
  install_package "$FZF_PKG" "$LOG"
done

# 如果 assets 中包含额外的 fish 主题或配置，可在此复制
if [ -d "assets/fish_themes" ]; then
    mkdir -p "$HOME/.config/fish/themes"
    cp -r assets/fish_themes/* "$HOME/.config/fish/themes/" >> "$LOG" 2>&1
    echo "${OK} 额外 fish 主题已复制。" | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
