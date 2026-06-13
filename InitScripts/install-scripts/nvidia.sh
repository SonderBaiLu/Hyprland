#!/bin/bash
# NVIDIA 相关配置 #

nvidia_pkg=(
  nvidia-dkms
  nvidia-settings
  nvidia-utils
  libva
  libva-nvidia-driver
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_nvidia.log"

# 检查其他 Hyprland 包并移除（如果有）
printf "${YELLOW} 正在检查其他 hyprland 包，如有则移除..${RESET}\n"
if pacman -Qs hyprland > /dev/null; then
  printf "${YELLOW} 检测到 Hyprland，正在移除以从官方仓库安装 Hyprland...${RESET}\n"
    for hyprnvi in hyprland-git hyprland-nvidia hyprland-nvidia-git hyprland-nvidia-hidpi-git; do
    sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a "$LOG" || true
    done
fi

# 安装额外的 Nvidia 软件包
printf "${YELLOW} 正在安装 ${SKY_BLUE}Nvidia 软件包和 Linux 头文件${RESET}...\n"
for krnl in $(cat /usr/lib/modules/*/pkgbase); do
  for NVIDIA in "${krnl}-headers" "${nvidia_pkg[@]}"; do
    install_package "$NVIDIA" "$LOG"
  done
done

# 检查 Nvidia 模块是否已添加到 mkinitcpio.conf，若未添加则添加
if grep -qE '^MODULES=.*nvidia. *nvidia_modeset.*nvidia_uvm.*nvidia_drm' /etc/mkinitcpio.conf; then
  echo "Nvidia 模块已包含在 /etc/mkinitcpio.conf 中" 2>&1 | tee -a "$LOG"
else
  sudo sed -Ei 's/^(MODULES=\([^\)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | tee -a "$LOG"
  echo "${OK} 已将 Nvidia 模块添加到 /etc/mkinitcpio.conf"
fi

printf "\n%.0s" {1..1}
printf "${INFO} 正在重新生成 ${YELLOW}Initramfs${RESET}...\n" 2>&1 | tee -a "$LOG"
sudo mkinitcpio -P 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..1}

# 额外的 Nvidia 步骤
NVEA="/etc/modprobe.d/nvidia.conf"
if [ -f "$NVEA" ]; then
  printf "${INFO} 似乎 ${YELLOW}nvidia_drm modeset=1 fbdev=1${RESET} 已添加到您的系统中..继续下一步。"
  printf "\n"
else
  printf "\n"
  printf "${YELLOW} 正在向 $NVEA 添加选项..."
  sudo echo -e "options nvidia_drm modeset=1 fbdev=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | tee -a "$LOG"
  printf "\n"
fi

# 针对 GRUB 用户的额外操作
if [ -f /etc/default/grub ]; then
    printf "${INFO} 检测到 ${YELLOW}GRUB${RESET} 引导加载程序\n" 2>&1 | tee -a "$LOG"
    
    # 检查是否已存在 nvidia-drm.modeset=1
    if ! sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i -e 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
        printf "${OK} 已将 nvidia-drm.modeset=1 添加到 /etc/default/grub\n" 2>&1 | tee -a "$LOG"
    fi

    # 检查是否已存在 nvidia_drm.fbdev=1
    if ! sudo grep -q "nvidia_drm.fbdev=1" /etc/default/grub; then
        sudo sed -i -e 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia_drm.fbdev=1"/' /etc/default/grub
        printf "${OK} 已将 nvidia_drm.fbdev=1 添加到 /etc/default/grub\n" 2>&1 | tee -a "$LOG"
    fi

    # 如果修改了 grub 配置，则重新生成 GRUB 配置
    if sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub || sudo grep -q "nvidia_drm.fbdev=1" /etc/default/grub; then
       sudo grub-mkconfig -o /boot/grub/grub.cfg
       printf "${INFO} ${YELLOW}GRUB${RESET} 配置已重新生成\n" 2>&1 | tee -a "$LOG"
    fi
  
    printf "${OK} 针对 ${YELLOW}GRUB${RESET} 的额外步骤已完成\n" 2>&1 | tee -a "$LOG"
fi

# 针对 systemd-boot 用户的额外操作
if [ -f /boot/loader/loader.conf ]; then
    printf "${INFO} 检测到 ${YELLOW}systemd-boot${RESET} 引导加载程序\n" 2>&1 | tee -a "$LOG"
  
    backup_count=$(find /boot/loader/entries/ -type f -name "*.conf.bak" | wc -l)
    conf_count=$(find /boot/loader/entries/ -type f -name "*.conf" | wc -l)
  
    if [ "$backup_count" -ne "$conf_count" ]; then
        find /boot/loader/entries/ -type f -name "*.conf" | while read imgconf; do
            # 备份配置
            sudo cp "$imgconf" "$imgconf.bak"
            printf "${INFO} 已为 systemd-boot 加载器创建备份：%s\n" "$imgconf" 2>&1 | tee -a "$LOG"
            
            # 清理选项并更新 NVIDIA 设置
            sdopt=$(grep -w "^options" "$imgconf" | sed 's/\b nvidia-drm.modeset=[^ ]*\b//g' | sed 's/\b nvidia_drm.fbdev=[^ ]*\b//g')
            sudo sed -i "/^options/c${sdopt} nvidia-drm.modeset=1 nvidia_drm.fbdev=1" "$imgconf" 2>&1 | tee -a "$LOG"
        done

        printf "${OK} 针对 ${YELLOW}systemd-boot${RESET} 的额外步骤已完成\n" 2>&1 | tee -a "$LOG"
    else
        printf "${NOTE} ${YELLOW}systemd-boot${RESET} 已配置完毕...\n" 2>&1 | tee -a "$LOG"
    fi
fi

printf "\n%.0s" {1..2}
