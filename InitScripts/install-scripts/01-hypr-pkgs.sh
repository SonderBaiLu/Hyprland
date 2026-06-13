#!/bin/bash
# Hyprland 软件包

# 在此添加额外需要的软件包
Extra=(

)

# 核心 Hyprland 相关软件包（大多数是必需的，移除可能导致配置失效）
hypr_package=( 
  bc
  cliphist
  curl 
  grim 
  gvfs 
  gvfs-mtp
  hyprpolkitagent
  imagemagick
  inxi 
  jq
  kvantum
  libspng
  alacritty
  network-manager-applet 
  pamixer 
  pavucontrol
  playerctl
  python-requests
  python-pyquery
  qt5ct
  qt6ct
  qt6-svg
  rofi
  slurp 
  swappy 
  swaync 
  swww
  unzip # 后续步骤需要
  wallust 
  wget
  wl-clipboard
  wlogout
  xdg-user-dirs
  xdg-utils 
  yad
)

# 下面的软件包可以删除，但 dotfiles 可能无法完全正常工作
hypr_package_2=(
  brightnessctl 
  btop
  cava
  loupe
  fastfetch
  gnome-system-monitor
  mousepad 
  mpv
  mpv-mpris 
  nvtop
  nwg-look
  nwg-displays
  pacman-contrib
  qalculate-gtk
  yt-dlp
)

# 需要卸载的冲突软件包列表
uninstall=(
  aylurs-gtk-shell
  dunst
  cachyos-hyprland-settings
  mako
  rofi
  wallust-git
  rofi-lbonn-wayland
  rofi-lbonn-wayland-git
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hypr-pkgs.log"

# 移除冲突的软件包
overall_failed=0
printf "\n%s - 正在${SKY_BLUE}移除一些与 KooL 的 Hyprland 配置冲突的软件包${RESET}\n" "${NOTE}"
for PKG in "${uninstall[@]}"; do
  uninstall_package "$PKG" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    overall_failed=1
  fi
done

if [ $overall_failed -ne 0 ]; then
  echo -e "${ERROR} 部分软件包卸载失败，请检查日志。"
fi

printf "\n%.0s" {1..1}

# 安装主要组件
printf "\n%s - 正在安装${SKY_BLUE} KooL 的 Hyprland 必要软件包${RESET} .... \n" "${NOTE}"

for PKG1 in "${hypr_package[@]}" "${hypr_package_2[@]}" "${Extra[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
