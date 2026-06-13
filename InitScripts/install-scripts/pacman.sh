#!/bin/bash
# 为 pacman 添加额外特色设置 #

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pacman.log"

echo -e "${NOTE} 正在为 pacman.conf 添加 ${MAGENTA}额外特色${RESET} ... ${RESET}" 2>&1 | tee -a "$LOG"
pacman_conf="/etc/pacman.conf"

# 移除指定行的注释 '#'
lines_to_edit=(
    "Color"
    "CheckSpace"
    "VerbosePkgLists"
    "ParallelDownloads"
)

# 如果指定行被注释则取消注释
for line in "${lines_to_edit[@]}"; do
    if grep -q "^#$line" "$pacman_conf"; then
        sudo sed -i "s/^#$line/$line/" "$pacman_conf"
        echo -e "${CAT} 已取消注释：$line ${RESET}" 2>&1 | tee -a "$LOG"
    else
        echo -e "${CAT} $line 已是非注释状态。 ${RESET}" 2>&1 | tee -a "$LOG"
    fi
done

# 如果 ParallelDownloads 存在且 ILoveCandy 不存在，则在 ParallelDownloads 下方添加 ILoveCandy
if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
    sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
    echo -e "${CAT} 在 ${MAGENTA}ParallelDownloads${RESET} 之后添加了 ${MAGENTA}ILoveCandy${RESET}。 ${RESET}" 2>&1 | tee -a "$LOG"
else
    echo -e "${CAT} 似乎 ${YELLOW}ILoveCandy${RESET} 已经存在 ${RESET}，继续下一步.." 2>&1 | tee -a "$LOG"
fi

echo -e "${CAT} ${MAGENTA}Pacman.conf${RESET} 特色化完成 ${RESET}" 2>&1 | tee -a "$LOG"

# 更新 pacman 数据库
printf "\n%s - ${SKY_BLUE}正在同步 Pacman 软件仓库${RESET}\n" "${INFO}"
sudo pacman -Sy

printf "\n%.0s" {1..2}
