#!/bin/bash
# 脚本使用的全局函数 #

set -e

# 为输出消息设置一些颜色
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

# 显示进度的函数
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●") 
    local i=0

    tput civis 
    printf "\r${NOTE} 正在安装 ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${NOTE} 正在安装 ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))  
        sleep 0.3  
    done

    printf "\r${NOTE} 正在安装 ${YELLOW}%s${RESET} ... 完成！%-20s \n" "$package_name" ""
    tput cnorm  
}

# 使用 pacman 安装软件包的函数
install_package_pacman() {
  # 检查软件包是否已经安装
  if pacman -Q "$1" &>/dev/null ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} 已经安装，跳过..."
  else
    # 运行 pacman 并将所有输出重定向到日志文件
    (
      stdbuf -oL sudo pacman -S --noconfirm "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 

    # 二次检查软件包是否安装成功
    if pacman -Q "$1" &>/dev/null ; then
      echo -e "${OK} 软件包 ${YELLOW}$1${RESET} 已成功安装！"
    else
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} 安装失败。请检查 $LOG。您可能需要手动安装。"
    fi
  fi
}

ISAUR=$(command -v yay || command -v paru)
# 使用 yay 或 paru 安装软件包的函数
install_package() {
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} 已经安装，跳过..."
  else
    (
      stdbuf -oL $ISAUR -S --noconfirm "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1"  
    
    # 二次检查软件包是否安装成功
    if $ISAUR -Q "$1" &>> /dev/null ; then
      echo -e "${OK} 软件包 ${YELLOW}$1${RESET} 已成功安装！"
    else
      # 安装失败，退出以供检查日志
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} 安装失败 :( ，请检查 install.log。您可能需要手动安装！抱歉，我已经尽力了 :("
    fi
  fi
}

# 直接使用 yay 或 paru 安装软件包，不检查是否已安装
install_package_f() {
  (
    stdbuf -oL $ISAUR -S --noconfirm "$1" 2>&1
  ) >> "$LOG" 2>&1 &
  PID=$!
  show_progress $PID "$1"  

  # 二次检查软件包是否安装成功
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${OK} 软件包 ${YELLOW}$1${RESET} 已成功安装！"
  else
    # 安装失败，退出以供检查日志
    echo -e "\n${ERROR} ${YELLOW}$1${RESET} 安装失败 :( ，请检查 install.log。您可能需要手动安装！抱歉，我已经尽力了 :("
  fi
}

# 卸载软件包的函数
uninstall_package() {
  local pkg="$1"

  # 检查软件包是否安装
  if pacman -Qi "$pkg" &>/dev/null; then
    echo -e "${NOTE} 正在卸载 $pkg ..."
    sudo pacman -R --noconfirm "$pkg" 2>&1 | tee -a "$LOG" | grep -v "error: target not found"
    
    if ! pacman -Qi "$pkg" &>/dev/null; then
      echo -e "\e[1A\e[K${OK} $pkg 已卸载。"
    else
      echo -e "\e[1A\e[K${ERROR} $pkg 卸载失败。无需进一步操作。"
      return 1
    fi
  else
    echo -e "${INFO} 软件包 $pkg 未安装，跳过。"
  fi
  return 0
}
