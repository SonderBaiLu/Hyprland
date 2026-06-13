#!/bin/bash
# 用于桌面概览

if [[ $USE_PRESET = [Yy] ]]; then
  source ./preset.sh
fi

ags=(
    typescript
    npm
    meson
    glib2-devel
    gjs 
    gtk3 
    gtk-layer-shell 
    upower
    networkmanager 
    gobject-introspection 
    libdbusmenu-gtk3 
    libsoup3
)

# 要下载的特定标签
ags_tag="v1.9.0"

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

# 早早失败并使管道在任一命令失败时立即失败
set -eo pipefail

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/install-$(date +%d-%H%M%S)_ags.log"
MLOG="install-$(date +%d-%H%M%S)_ags2.log"

# 注意：我们在此有意不运行 `ags -v`，因为损坏的 AGS 安装（缺少 GUtils 等）
# 会在安装过程中导致 gjs 崩溃并喷出一堆错误。每次运行此脚本时，我们都会（重新）安装 v1.9.0。
printf "\n%s - 正在安装 ${SKY_BLUE}Aylur 的 GTK shell $ags_tag${RESET} 的依赖项 \n" "${NOTE}"

# 安装 ags 的依赖项
for PKG1 in "${ags[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}

# ags v1
printf "${NOTE} 正在安装并编译 ${SKY_BLUE}Aylur 的 GTK shell $ags_tag${RESET}..\n"

# 检查目录是否存在并移除它
if [ -d "ags_v1.9.0" ]; then
    printf "${NOTE} 正在移除现有的 ags 目录...\n"
    rm -rf "ags_v1.9.0"
fi

printf "\n%.0s" {1..1}
printf "${INFO} 请稍候...正在克隆并编译 ${SKY_BLUE}Aylur 的 GTK shell $ags_tag${RESET}...\n"
printf "\n%.0s" {1..1}
# 使用指定标签克隆仓库并编译 AGS
if git clone --depth=1 https://github.com/JaKooLit/ags_v1.9.0.git; then
    cd ags_v1.9.0 || exit 1

    # 修补 tsconfig 以避免 TS5107 错误（moduleResolution=node10 被废弃）
    if [ -f tsconfig.json ]; then
        # 1) 确保 ignoreDeprecations 存在
        if ! grep -q '"ignoreDeprecations"[[:space:]]*:' tsconfig.json; then
            sed -i 's/"compilerOptions":[[:space:]]*{/"compilerOptions": {\n    "ignoreDeprecations": "6.0",/' tsconfig.json
        fi
        # 2) 如果 moduleResolution 为 node10，则升级为 node16
        if grep -q '"moduleResolution"[[:space:]]*:[[:space:]]*"node10"' tsconfig.json; then
            sed -i 's/"moduleResolution"[[:space:]]*:[[:space:]]*"node10"/"moduleResolution": "node16"/' tsconfig.json || true
        fi
        # 3) 如果 sed 未能捕获模式，用 Node 回退方案重写 JSON
        if grep -q '"moduleResolution"[[:space:]]*:[[:space:]]*"node10"' tsconfig.json; then
            if command -v node >/dev/null 2>&1; then
                node -e '\n                const fs = require("fs");\n                const p = "tsconfig.json";\n                const j = JSON.parse(fs.readFileSync(p, "utf8"));\n                j.compilerOptions = j.compilerOptions || {};\n                if (j.compilerOptions.moduleResolution === "node10") j.compilerOptions.moduleResolution = "node16";\n                if (j.compilerOptions.ignoreDeprecations === undefined) j.compilerOptions.ignoreDeprecations = "6.0";\n                fs.writeFileSync(p, JSON.stringify(j, null, 2));\n                '
            fi
        fi
        # 记录修补后的结果以便排查问题
        echo "== tsconfig.json 修补后内容 ==" >> "$MLOG"
        grep -n 'moduleResolution\|ignoreDeprecations' tsconfig.json >> "$MLOG" || true
    fi

    # 用完全不依赖 GUtils 的存根替换 pam.ts。
    # 桌面概览功能不使用 PAM，而各发行版对 GUtils typelib 的支持情况不一致，
    # 因此我们禁用这些辅助功能，避免因 typelib 缺失而在启动时崩溃。
    if [ -f src/utils/pam.ts ]; then
        printf "%s 正在用 PAM 存根替换 src/utils/pam.ts（无 GUtils 依赖）...\\n" "${NOTE}" | tee -a "$MLOG"
        cat > src/utils/pam.ts <<'PAM_STUB'
// 为通过 Arch-Hyprland 安装的 AGS 提供的 PAM 认证存根。
// 桌面概览不使用 PAM，而各发行版对 GUtils typelib 的支持不可靠，
// 因此我们在这里禁用这些辅助功能。

export function authenticate(password: string): Promise<number> {
    return Promise.reject(new Error("此系统上 PAM 认证已禁用（无 GUtils）"));
}

export function authenticateUser(username: string, password: string): Promise<number> {
    return Promise.reject(new Error("此系统上 PAM 认证已禁用（无 GUtils）"));
}
PAM_STUB
    fi

    npm install
    meson setup build
    if sudo meson install -C build 2>&1 | tee -a "$MLOG"; then
        printf "\n${OK} ${YELLOW}Aylur 的 GTK shell $ags_tag${RESET} 安装成功。\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "\n${ERROR} ${YELLOW}Aylur 的 GTK shell $ags_tag${RESET} 安装失败\n " 2>&1 | tee -a "$MLOG"
        # 构建/安装失败时在此中止，避免安装损坏的启动器或报告 AGS 二进制文件缺失时仍显示成功。
        mv "$MLOG" ../Install-Logs/ || true
        cd ..
        exit 1
    fi

    LAUNCHER_DIR="/usr/local/share/com.github.Aylur.ags"
    LAUNCHER_PATH="$LAUNCHER_DIR/com.github.Aylur.ags"
    sudo mkdir -p "$LAUNCHER_DIR"

    # 安装已知可用的启动器，该启动器是从一个正常工作的系统上捕获的。
    # 此 JS 入口脚本使用 GLib 设置 GI_TYPELIB_PATH 且不依赖 GIRepository，
    # 从而避免了 typelib 缺失导致的崩溃。
    LAUNCHER_SRC="$SCRIPT_DIR/ags.launcher.com.github.Aylur.ags"
    if [ -f "$LAUNCHER_SRC" ]; then
        sudo install -m 755 "$LAUNCHER_SRC" "$LAUNCHER_PATH"
    else
        printf "${WARN} 在 %s 处未找到保存的启动器；保持 Meson 安装的启动器不变。\\n" "$LAUNCHER_SRC" | tee -a "$MLOG"
    fi

    # 确保 /usr/local/bin/ags 指向 JS 入口脚本
    sudo mkdir -p /usr/local/bin
    sudo ln -srf "$LAUNCHER_PATH" /usr/local/bin/ags
    printf "${OK} AGS 启动器已安装。\\n"
    # 将日志移动到 Install-Logs 目录
    mv "$MLOG" ../Install-Logs/ || true
    cd ..
else
    echo -e "\n${ERROR} 无法下载 ${YELLOW}Aylur 的 GTK shell $ags_tag${RESET}，请检查网络连接\n" 2>&1 | tee -a "$LOG"
    mv "$MLOG" ../Install-Logs/ || true
    exit 1
fi

printf "\n%.0s" {1..2}
