#!/bin/bash
# Paru AUR 助手 #
# 注意：如果 yay 已安装，则不会安装 paru #

pkg="paru-bin"

## 警告：如果您不知道自己在做什么，请勿编辑此行之后的内容！ ##
# 设置日志文件名，包含当前日期和时间
LOG="install-$(date +%d-%H%M%S)_yay.log"

# 为输出消息设置颜色
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[错误]$(tput sgr0)"
NOTE="$(tput setaf 3)[注意]$(tput sgr0)"
INFO="$(tput setaf 4)[信息]$(tput sgr0)"
WARN="$(tput setaf 1)[警告]$(tput sgr0)"
CAT="$(tput setaf 6)[操作]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# 创建安装日志目录
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# 检查 AUR 助手，如果未安装则进行安装
ISAUR=$(command -v yay || command -v paru)
if [ -n "$ISAUR" ]; then
  printf "\n%s - ${SKY_BLUE}AUR 助手${RESET} 已安装，继续下一步。\n" "${OK}"
else
  printf "\n%s - 正在从 AUR 安装 ${SKY_BLUE}$pkg${RESET}\n" "${NOTE}"

  # 检查目录是否存在并删除
  if [ -d "$pkg" ]; then
    rm -rf "$pkg"
  fi
  git clone https://aur.archlinux.org/$pkg.git || { printf "%s - 从 AUR 克隆 ${YELLOW}$pkg${RESET} 失败\n" "${ERROR}"; exit 1; }
  cd $pkg || { printf "%s - 进入 $pkg 目录失败\n" "${ERROR}"; exit 1; }
  makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - 从 AUR 安装 ${YELLOW}$pkg${RESET} 失败\n" "${ERROR}"; exit 1; }

  # 将安装日志移动到 Install-Logs 目录
  mv install*.log ../Install-Logs/ || true   
  cd ..
fi

# 在继续之前更新整个系统
printf "\n%s - 正在执行完整系统更新以避免问题.... \n" "${NOTE}"
ISAUR=$(command -v yay || command -v paru)

$ISAUR -Syu --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - 系统更新失败\n" "${ERROR}"; exit 1; }

printf "\n%.0s" {1..2}
