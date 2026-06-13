#!/bin/bash
# SDDM 登录管理器 #

sddm=(
  qt6-declarative
  qt6-svg
  qt6-virtualkeyboard
  qt6-multimedia-ffmpeg
  qt5-quickcontrols2
  sddm
)

# 尝试禁用的其他登录管理器
login=(
  lightdm
  gdm3
  gdm
  lxdm
  lxdm-gtk3
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm.log"

# 安装 SDDM 及其依赖
printf "${NOTE} 正在安装 sddm 及依赖........\n"
for package in "${sddm[@]}"; do
  install_package "$package" "$LOG"
done

printf "\n%.0s" {1..1}

# 检查其他登录管理器是否已安装，并在启用 sddm 前禁用其服务
for login_manager in "${login[@]}"; do
  if pacman -Qs "$login_manager" >/dev/null 2>&1; then
    sudo systemctl disable "$login_manager.service" >>"$LOG" 2>&1
    echo "$login_manager 已禁用。" >>"$LOG" 2>&1
  fi
done

# 使用 systemctl 二次确认
for manager in "${login[@]}"; do
  if systemctl is-active --quiet "$manager" >/dev/null 2>&1; then
    echo "$manager 正在运行，正在禁用它..." >>"$LOG" 2>&1
    sudo systemctl disable "$manager" --now >>"$LOG" 2>&1
  fi
done

printf "\n%.0s" {1..1}
printf "${INFO} 正在启用 sddm 服务........\n"
sudo systemctl enable sddm

wayland_sessions_dir=/usr/share/wayland-sessions
[ ! -d "$wayland_sessions_dir" ] && {
  printf "$CAT - $wayland_sessions_dir 未找到，正在创建...\n"
  sudo mkdir "$wayland_sessions_dir" 2>&1 | tee -a "$LOG"
}

printf "\n%.0s" {1..2}
