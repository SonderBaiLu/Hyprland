#!/bin/bash
# GTK 主题与图标，从另一个仓库获取 #
engine=(
    unzip
    gtk-engine-murrine
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_themes.log"

# 安装 GTK 主题所需的引擎
for PKG1 in "${engine[@]}"; do
    install_package "$PKG1" "$LOG"
done

# 检查目录是否存在，若存在则删除
if [ -d "GTK-themes-icons" ]; then
    echo "$NOTE GTK 主题与图标目录已存在，正在删除..." 2>&1 | tee -a "$LOG"
    rm -rf "GTK-themes-icons" 2>&1 | tee -a "$LOG"
fi

echo "$NOTE 正在克隆 ${SKY_BLUE}GTK 主题与图标${RESET} 仓库..." 2>&1 | tee -a "$LOG"
if git clone --depth=1 https://github.com/JaKooLit/GTK-themes-icons.git ; then
    cd GTK-themes-icons
    chmod +x auto-extract.sh
    ./auto-extract.sh
    cd ..
    echo "$OK 已将 GTK 主题与图标提取到 ~/.icons 和 ~/.themes 目录" 2>&1 | tee -a "$LOG"
else
    echo "$ERROR 下载 GTK 主题与图标失败..." 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
