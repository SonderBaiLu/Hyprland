#!/bin/bash
# 最终检查软件包是否已安装
# 注意：这些检查仅限于必要的软件包

packages=(
  cliphist
  kvantum
  rofi-wayland
  imagemagick
  swaync
  swww
  wallust
  wl-clipboard
  wlogout
  alacritty
  hypridle
  hyprlock
  hyprland
)

# 应该位于 /usr/local/bin/ 的本地软件包
local_pkgs_installed=(

)

## 警告：如果您不清楚自己在做什么，请不要编辑此行以下的内容！ ##
# 确定脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 将工作目录切换到脚本所在目录的上级目录
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} 无法切换到目录 $PARENT_DIR"; exit 1; }

# 加载全局函数脚本
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/00_CHECK-$(date +%d-%H%M%S)_installed.log"

printf "\n%s - 最终检查：是否所有${SKY_BLUE}必要软件包${RESET}都已安装 \n" "${NOTE}"
# 初始化一个空数组用于保存缺失的软件包
missing=()
local_missing=()

# 函数：使用 pacman 检查软件包是否已安装
is_installed_pacman() {
    pacman -Qi "$1" &>/dev/null
}

# 遍历每个软件包
for pkg in "${packages[@]}"; do
    # 检查软件包是否已安装
    if ! is_installed_pacman "$pkg"; then
        missing+=("$pkg")
    fi
done

# 检查本地软件包
for pkg1 in "${local_pkgs_installed[@]}"; do
    if ! [ -f "/usr/local/bin/$pkg1" ]; then
        local_missing+=("$pkg1")
    fi
done

# 记录缺失的软件包
if [ ${#missing[@]} -eq 0 ] && [ ${#local_missing[@]} -eq 0 ]; then
    echo "${OK} 太好了！所有 ${YELLOW}必要软件包${RESET} 已成功安装。" | tee -a "$LOG"
else
    if [ ${#missing[@]} -ne 0 ]; then
        echo "${WARN} 以下软件包未安装，将被记录："
        for pkg in "${missing[@]}"; do
            echo "${WARNING}$pkg${RESET}"
            echo "$pkg" >> "$LOG" 
        done
    fi

    if [ ${#local_missing[@]} -ne 0 ]; then
        echo "${WARN} 以下本地软件包在 /usr/local/bin/ 中缺失，将被记录："
        for pkg1 in "${local_missing[@]}"; do
            echo "${WARNING}$pkg1${RESET} 未安装。在 /usr/local/bin/ 中未找到它"
            echo "$pkg1" >> "$LOG" 
        done
    fi

    echo "${NOTE} 缺失软件包已记录于 $(date)" >> "$LOG"
fi
