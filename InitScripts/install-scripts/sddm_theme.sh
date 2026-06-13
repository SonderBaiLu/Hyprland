#!/bin/bash
# SDDM 主题 #

source_theme="https://github.com/JaKooLit/simple-sddm-2.git"
theme_name="simple_sddm_2"

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm_theme.log"
    
# SDDM 主题
printf "${INFO} 正在安装 ${SKY_BLUE}额外的 SDDM 主题${RESET}\n"

# 检查 /usr/share/sddm/themes/$theme_name 是否存在，如果存在则删除
if [ -d "/usr/share/sddm/themes/$theme_name" ]; then
  sudo rm -rf "/usr/share/sddm/themes/$theme_name"
  echo -e "\e[1A\e[K${OK} - 已删除现有的 $theme_name 目录。" 2>&1 | tee -a "$LOG"
fi

# 检查当前目录下是否存在 $theme_name 目录，如果存在则删除
if [ -d "$theme_name" ]; then
  rm -rf "$theme_name"
  echo -e "\e[1A\e[K${OK} - 已从当前位置删除现有的 $theme_name 目录。" 2>&1 | tee -a "$LOG"
fi

# 克隆仓库
if git clone --depth=1 "$source_theme" "$theme_name"; then
  if [ ! -d "$theme_name" ]; then
    echo "${ERROR} 克隆仓库失败。" | tee -a "$LOG"
  fi

  # 如果主题目录不存在，则创建
  if [ ! -d "/usr/share/sddm/themes" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    echo "${OK} - 目录 '/usr/share/sddm/themes' 已创建。" | tee -a "$LOG"
  fi

  # 将克隆的主题移动到 themes 目录
  sudo mv "$theme_name" "/usr/share/sddm/themes/$theme_name" 2>&1 | tee -a "$LOG"

  # 设置 SDDM 主题
  sddm_conf="/etc/sddm.conf"
  BACKUP_SUFFIX=".bak"

  echo -e "${NOTE} 正在设置登录界面。" | tee -a "$LOG"

  # 如果 sddm.conf 文件存在，则备份
  if [ -f "$sddm_conf" ]; then
    echo "正在备份 $sddm_conf" | tee -a "$LOG"
    sudo cp "$sddm_conf" "$sddm_conf$BACKUP_SUFFIX" 2>&1 | tee -a "$LOG"
  else
    echo "$sddm_conf 不存在，正在创建新文件。" | tee -a "$LOG"
    sudo touch "$sddm_conf" 2>&1 | tee -a "$LOG"
  fi

  # 检查 [Theme] 部分是否存在
  if grep -q '^\[Theme\]' "$sddm_conf"; then
    # 更新 [Theme] 下的 Current= 行
    sudo sed -i "/^\[Theme\]/,/^\[/{s/^\s*Current=.*/Current=$theme_name/}" "$sddm_conf" 2>&1 | tee -a "$LOG"
    
    # 如果没有找到并替换 Current= 行，则在 [Theme] 部分之后追加
    if ! grep -q '^\s*Current=' "$sddm_conf"; then
      sudo sed -i "/^\[Theme\]/a Current=$theme_name" "$sddm_conf" 2>&1 | tee -a "$LOG"
      echo "已在 $sddm_conf 的 [Theme] 下追加 Current=$theme_name" | tee -a "$LOG"
    else
      echo "已在 $sddm_conf 中更新 Current=$theme_name" | tee -a "$LOG"
    fi
  else
    # 如果 [Theme] 部分不存在，则在末尾追加
    echo -e "\n[Theme]\nCurrent=$theme_name" | sudo tee -a "$sddm_conf" > /dev/null
    echo "已在 $sddm_conf 中添加 [Theme] 部分并设置 Current=$theme_name" | tee -a "$LOG"
  fi

  # 如果 [General] 部分不存在，则添加并设置 InputMethod=qtvirtualkeyboard
  if ! grep -q '^\[General\]' "$sddm_conf"; then
    echo -e "\n[General]\nInputMethod=qtvirtualkeyboard" | sudo tee -a "$sddm_conf" > /dev/null
    echo "已在 $sddm_conf 中添加 [General] 部分并设置 InputMethod=qtvirtualkeyboard" | tee -a "$LOG"
  else
    # 如果部分存在，则更新 InputMethod 行
    if grep -q '^\s*InputMethod=' "$sddm_conf"; then
      sudo sed -i '/^\[General\]/,/^\[/{s/^\s*InputMethod=.*/InputMethod=qtvirtualkeyboard/}' "$sddm_conf" 2>&1 | tee -a "$LOG"
      echo "已在 $sddm_conf 中将 InputMethod 更新为 qtvirtualkeyboard" | tee -a "$LOG"
    else
      sudo sed -i '/^\[General\]/a InputMethod=qtvirtualkeyboard' "$sddm_conf" 2>&1 | tee -a "$LOG"
      echo "已在 $sddm_conf 的 [General] 下追加 InputMethod=qtvirtualkeyboard" | tee -a "$LOG"
    fi
  fi

  # 替换默认背景图片
  sudo cp -r assets/sddm.png "/usr/share/sddm/themes/$theme_name/Backgrounds/default" 2>&1 | tee -a "$LOG"
  sudo sed -i 's|^wallpaper=".*"|wallpaper="Backgrounds/default"|' "/usr/share/sddm/themes/$theme_name/theme.conf" 2>&1 | tee -a "$LOG"

  echo "${OK} - ${MAGENTA}额外的 ${YELLOW}$theme_name SDDM 主题${RESET} 已成功安装。" | tee -a "$LOG"

else

  echo "${ERROR} - 克隆 SDDM 主题仓库失败，请检查网络连接。" | tee -a "$LOG" >&2
fi

printf "\n%.0s" {1..2}
