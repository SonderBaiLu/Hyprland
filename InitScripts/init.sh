#!/bin/bash
clear

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

# 设置日志文件名，包含当前日期和时间
LOG="Install-Logs/01-Hyprland-Install-Scripts-$(date +%d-%H%M%S).log"

# 检查是否以 root 身份运行，如果是则退出
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  此脚本${WARNING}不应${RESET}以 root 身份执行！！正在退出……" | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# 检查是否已安装 PulseAudio 包
if pacman -Qq | grep -qw '^pulseaudio$'; then
    echo "$ERROR 检测到 PulseAudio 已安装。请先卸载它，或编辑 install.sh 中第 211 行 (execute_script 'pipewire.sh')。" | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# 检查 base-devel 是否已安装
if pacman -Q base-devel &> /dev/null; then
    echo "base-devel 已安装。"
else
    echo "$NOTE 正在安装 base-devel……"

    if sudo pacman -S --noconfirm base-devel; then
        echo "👌 ${OK} base-devel 已成功安装。" | tee -a "$LOG"
    else
        echo "❌ $ERROR 未找到 base-devel 或无法安装。"  | tee -a "$LOG"
        echo "$ACTION 请在运行此脚本前手动安装 base-devel……正在退出" | tee -a "$LOG"
        exit 1
    fi
fi

# 若检测到 whiptail 未安装，则进行安装（此版本必要）
if ! command -v whiptail >/dev/null; then
    echo "${NOTE} - whiptail 未安装，正在安装……" | tee -a "$LOG"
    sudo pacman -S --noconfirm libnewt
    printf "\n%.0s" {1..1}
fi

clear

printf "\n%.0s" {1..2}  
echo -e "\e[35m
	╦╔═┌─┐┌─┐╦    ╦ ╦┬ ┬┌─┐┬─┐┬  ┌─┐┌┐┌┌┬┐
	╠╩╗│ ││ │║    ╠═╣└┬┘├─┘├┬┘│  ├─┤│││ ││ 2025
	╩ ╩└─┘└─┘╩═╝  ╩ ╩ ┴ ┴  ┴└─┴─┘┴ ┴┘└┘─┴┘ Arch Linux
\e[0m"
printf "\n%.0s" {1..1} 

# 使用 whiptail 显示欢迎信息
whiptail --title "KooL Arch-Hyprland (2025) 安装脚本" \
    --msgbox "欢迎使用 KooL Arch-Hyprland (2025) 安装脚本！！！\n\n\
注意：请先执行完整的系统更新并重启！（强烈推荐）\n\n\
注意：如果您在虚拟机中安装，请确保启用 3D 加速，否则 Hyprland 可能无法启动！" \
    15 80

# 询问用户是否继续
if ! whiptail --title "是否继续安装？" \
    --yesno "您想继续吗？" 7 50; then
    echo -e "\n"
    echo "❌ ${INFO} 您🫵选择了${YELLOW}不${RESET}继续。${YELLOW}正在退出……${RESET}" | tee -a "$LOG"
    echo -e "\n" 
    exit 1
fi

echo "👌 ${OK} 🇵🇭 ${MAGENTA}KooL..${RESET} ${SKY_BLUE}让我们继续安装……${RESET}" | tee -a "$LOG"

sleep 1
printf "\n%.0s" {1..1}

# 若检测到 pciutils 未安装，则进行安装（用于检测 GPU 必要）
if ! pacman -Qs pciutils > /dev/null; then
    echo "${NOTE} - pciutils 未安装，正在安装……" | tee -a "$LOG"
    sudo pacman -S --noconfirm pciutils
    printf "\n%.0s" {1..1}
fi

# 安装脚本所在目录
script_directory=install-scripts

# 函数：如果脚本存在则执行，并赋予执行权限
execute_script() {
    local script="$1"
    local script_path="$script_directory/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            env "$script_path"
        else
            echo "无法使脚本 '$script' 变为可执行。"
        fi
    else
        echo "在 '$script_directory' 中未找到脚本 '$script'。"
    fi
}


## 选项的默认值（若存在预设文件则会被覆盖）
gtk_themes="OFF"
bluetooth="OFF"
index="OFF"
quickshell="OFF"
sddm="OFF"
sddm_theme="OFF"
xdph="OFF"
fish="OFF"
pokemon="OFF"
rog="OFF"
dots="OFF"
input_group="OFF"
nvidia="OFF"
nouveau="OFF"

# 加载预设文件的函数
load_preset() {
    if [ -f "$1" ]; then
        echo "✅ 正在加载预设：$1"
        source "$1"
    else
        echo "⚠️ 未找到预设文件：$1。将使用默认值。"
    fi
}

# 检查是否传递了 --preset 参数
if [[ "$1" == "--preset" && -n "$2" ]]; then
    load_preset "$2"
fi

# 检查 yay 或 paru 是否已安装
echo "${INFO} - 正在检查 yay 或 paru 是否已安装"
if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    echo "${CAT} - 未找到 yay 也未找到 paru。正在询问 🗣️ 用户选择……"
    while true; do
        aur_helper=$(whiptail --title "未安装 Yay 或 Paru" --checklist "未安装 Yay 或 Paru。请选择一个 AUR 助手。\n\n注意：仅选择 1 个 AUR 助手！\n信息：使用空格键选择" 12 60 2 \
            "yay" "AUR 助手 yay" "OFF" \
            "paru" "AUR 助手 paru" "OFF" \
            3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then  
            echo "❌ ${INFO} 您取消了选择。${YELLOW}再见！${RESET}" | tee -a "$LOG"
            exit 0 
        fi

        if [ -z "$aur_helper" ]; then
            whiptail --title "错误" --msgbox "您必须至少选择一个 AUR 助手才能继续。" 10 60 2
            continue 
        fi

        echo "${INFO} - 您选择了：$aur_helper 作为您的 AUR 助手"  | tee -a "$LOG"

        aur_helper=$(echo "$aur_helper" | tr -d '"')

        # 检查是否选择了多个助手
        if [[ $(echo "$aur_helper" | wc -w) -ne 1 ]]; then
            whiptail --title "错误" --msgbox "您必须恰好选择一个 AUR 助手。" 10 60 2
            continue  
        else
            break 
        fi
    done
else
    echo "${NOTE} - AUR 助手已安装，跳过 AUR 助手选择。"
fi

# 需要检查的登录管理器服务列表
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# 函数：检查是否有登录服务正在运行
check_services_running() {
    active_services=()  # 存储活动服务的数组
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            active_services+=("$svc")  
        fi
    done

    if [ ${#active_services[@]} -gt 0 ]; then
        return 0  
    else
        return 1  
    fi
}

if check_services_running; then
    active_list=$(printf "%s\n" "${active_services[@]}")

    # 在 whiptail 消息框中显示活动的登录管理器
    whiptail --title "检测到活动的非 SDDM 登录管理器" \
        --msgbox "以下登录管理器正在运行：\n\n$active_list\n\n如果您想安装 SDDM 和 SDDM 主题，请先停止并禁用上述服务，重启后再运行此脚本\n\n您安装 SDDM 和 SDDM 主题的选项已被移除\n\n- Ja " 23 80
fi

# 检查是否检测到 NVIDIA GPU
nvidia_detected=false
if lspci | grep -i "nvidia" &> /dev/null; then
    nvidia_detected=true
    whiptail --title "检测到 NVIDIA GPU" --msgbox "您的系统中检测到 NVIDIA GPU。\n\n注意：如果您选择配置，脚本将安装 nvidia-dkms、nvidia-utils 和 nvidia-settings。" 12 60
fi

# 初始化 whiptail 选项数组
options_command=(
    whiptail --title "选择选项" --checklist "选择要安装或配置的选项\n注意：使用 '空格键' 选择，'TAB 键' 切换选项" 28 85 20
)

# 如果检测到 NVIDIA，添加 NVIDIA 相关选项
if [ "$nvidia_detected" == "true" ]; then
    options_command+=(
        "nvidia" "是否希望脚本配置 NVIDIA GPU？" "OFF"
        "nouveau" "是否希望将 Nouveau 加入黑名单？" "OFF"
    )
fi

# 如果用户不在 input 组中，则添加 'input_group' 选项
input_group_detected=false
if ! groups "$(whoami)" | grep -q '\binput\b'; then
    input_group_detected=true
    whiptail --title "Input 组" --msgbox "您当前不在 input 组中。\n\n将您添加到 input 组对于 Waybar 的键盘状态功能可能是必要的。" 12 60
fi

# 如有必要，添加 'input_group' 选项
if [ "$input_group_detected" == "true" ]; then
    options_command+=(
        "input_group" "将您的用户添加到 input 组以实现某些 waybar 功能？" "OFF"
    )
fi

# 如果没有检测到活动的登录管理器，则添加 SDDM 和 SDDM 主题选项
if ! check_services_running; then
    options_command+=(
        "sddm" "安装并配置 SDDM 登录管理器？" "OFF"
        "sddm_theme" "下载并安装额外的 SDDM 主题？" "OFF"
    )
fi

# 添加剩余的静态选项
options_command+=(
    "gtk_themes" "安装 GTK 主题？（深色/浅色功能需要）" "OFF"
    "bluetooth" "是否希望脚本配置蓝牙？" "OFF"
    "Index" "是否安装 Index 文件管理器？" "OFF"
    "quickshell" "安装 quickshell 以实现桌面概览？" "OFF"
    "xdph" "安装 XDG-DESKTOP-PORTAL-HYPRLAND（用于屏幕共享）？" "OFF"
    "fish" "安装 fish ？" "OFF"
    "pokemon" "为您的终端添加 Pokemon 彩色脚本？" "OFF"
    "rog" "您是否在 Asus ROG 笔记本上安装？" "OFF"
    "dots" "下载并安装预配置的 KooL Hyprland 配置（dotfiles）？" "OFF"
)

# 在 while 循环开始前捕获选择的选项
while true; do
    selected_options=$("${options_command[@]}" 3>&1 1>&2 2>&3)

    # 检查用户是否按了取消（退出状态 1）
    if [ $? -ne 0 ]; then
        echo -e "\n"
        echo "❌ ${INFO} 您🫵取消了选择。${YELLOW}再见！${RESET}" | tee -a "$LOG"
        exit 0  # 如果按了取消，退出脚本
    fi

    # 如果没有选项被选中，提示并重新开始选择
    if [ -z "$selected_options" ]; then
        whiptail --title "警告" --msgbox "未选择任何选项。请至少选择一个选项。" 10 60
        continue  # 如果未选择任何选项，返回选择界面
    fi

    # 去除引号并修剪多余空格（清理输入）
    selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

    # 将选中的选项转换为数组（保留值中的空格）
    IFS=' ' read -r -a options <<< "$selected_options"

    # 检查是否选择了 "dots" 选项
    dots_selected="OFF"
    for option in "${options[@]}"; do
        if [[ "$option" == "dots" ]]; then
            dots_selected="ON"
            break
        fi
    done

    # 如果未选择 "dots"，则显示提示并询问用户是继续还是返回选择
    if [[ "$dots_selected" == "OFF" ]]; then
        # 显示关于未选择 "dots" 的提示
        if ! whiptail --title "KooL Hyprland 配置文件" --yesno \
        "您未选择安装预配置的 KooL Hyprland 配置文件。\n\n请注意，如果您在没有配置文件的情况下继续，Hyprland 将以默认的普通配置启动，我无法为您提供支持。\n\n您是否想在不安装 KooL Hyprland 配置文件的情况下继续安装，还是返回选项？" \
        --yes-button "继续" --no-button "返回" 15 90; then
            echo "🔙 返回选项……" | tee -a "$LOG"
            continue
        else
            # 用户选择继续
            echo "${INFO} ⚠️ 在不安装配置文件的情况下继续……" | tee -a "$LOG"
			printf "\n%.0s" {1..1}
        fi
    fi

    # 准备确认信息
    confirm_message="您选择了以下选项：\n\n"
    for option in "${options[@]}"; do
        confirm_message+=" - $option\n"
    done
    confirm_message+="\n您对这些选择满意吗？"

    # 确认提示
    if ! whiptail --title "确认您的选择" --yesno "$(printf "%s" "$confirm_message")" 25 80; then
        echo -e "\n"
        echo "❌ ${SKY_BLUE}您🫵不满意${RESET}。${YELLOW}返回选项……${RESET}" | tee -a "$LOG"
        continue 
    fi

    echo "👌 ${OK} 您确认了您的选择。继续 ${SKY_BLUE}KooL 🇵🇭 Hyprland 安装……${RESET}" | tee -a "$LOG"
    break  
done

printf "\n%.0s" {1..1}

# 确保 base-devel 已安装
execute_script "00-base.sh"
sleep 1
execute_script "pacman.sh"
sleep 1

# 如果适用，在其他安装之后执行 AUR 助手脚本
if [ "$aur_helper" == "paru" ]; then
    execute_script "paru.sh"
elif [ "$aur_helper" == "yay" ]; then
    execute_script "yay.sh"
fi

sleep 1

# 运行与 Hyprland 相关的脚本
echo "${INFO} 正在安装 ${SKY_BLUE}KooL Hyprland 额外软件包……${RESET}" | tee -a "$LOG"
sleep 1
execute_script "01-hypr-pkgs.sh"

echo "${INFO} 正在安装 ${SKY_BLUE}pipewire 和 pipewire-audio……${RESET}" | tee -a "$LOG"
sleep 1
execute_script "pipewire.sh"

echo "${INFO} 正在安装 ${SKY_BLUE}必要字体……${RESET}" | tee -a "$LOG"
sleep 1
execute_script "fonts.sh"

echo "${INFO} 正在安装 ${SKY_BLUE}Hyprland……${RESET}"
sleep 1
execute_script "hyprland.sh"

# 清理选中的选项（去除引号并修剪空格）
selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

# 将选中的选项转换为数组（按空格分割）
IFS=' ' read -r -a options <<< "$selected_options"

# 遍历选中的选项
for option in "${options[@]}"; do
    case "$option" in
        sddm)
            if check_services_running; then
                active_list=$(printf "%s\n" "${active_services[@]}")
                whiptail --title "错误" --msgbox "以下登录服务之一正在运行：\n$active_list\n\n请停止并禁用它，或者不选择 SDDM。" 12 60
                exec "$0"  
            else
                echo "${INFO} 正在安装和配置 ${SKY_BLUE}SDDM……${RESET}" | tee -a "$LOG"
                execute_script "sddm.sh"
            fi
            ;;
        nvidia)
            echo "${INFO} 正在配置 ${SKY_BLUE}nvidia 相关${RESET}" | tee -a "$LOG"
            execute_script "nvidia.sh"
            ;;
        nouveau)
            echo "${INFO} 正在将 ${SKY_BLUE}nouveau${RESET} 加入黑名单"
            execute_script "nvidia_nouveau.sh" | tee -a "$LOG"
            ;;
        gtk_themes)
            echo "${INFO} 正在安装 ${SKY_BLUE}GTK 主题……${RESET}" | tee -a "$LOG"
            execute_script "gtk_themes.sh"
            ;;
        input_group)
            echo "${INFO} 正在将用户添加到 ${SKY_BLUE}input 组……${RESET}" | tee -a "$LOG"
            execute_script "InputGroup.sh"
            ;;
        quickshell)
            echo "${INFO} 正在安装 ${SKY_BLUE}quickshell 以实现桌面概览……${RESET}" | tee -a "$LOG"
            execute_script "quickshell.sh"
            ;;
        xdph)
            echo "${INFO} 正在安装 ${SKY_BLUE}xdg-desktop-portal-hyprland……${RESET}" | tee -a "$LOG"
            execute_script "xdph.sh"
            ;;
        bluetooth)
            echo "${INFO} 正在配置 ${SKY_BLUE}蓝牙……${RESET}" | tee -a "$LOG"
            execute_script "bluetooth.sh"
            ;;
        Index)
            echo "${INFO} 正在安装 ${SKY_BLUE}Index 文件管理器……${RESET}" | tee -a "$LOG"
            execute_script "index_fm.sh"
            execute_script "index_fm_default.sh"
            ;;
        sddm_theme)
            echo "${INFO} 正在下载并安装 ${SKY_BLUE}额外的 SDDM 主题……${RESET}" | tee -a "$LOG"
            execute_script "sddm_theme.sh"
            ;;
        fish)
            echo "${INFO} 正在安装 ${SKY_BLUE}fish ……${RESET}" | tee -a "$LOG"
            execute_script "fish.sh"
            ;;
        rog)
            echo "${INFO} 正在安装 ${SKY_BLUE}ROG 笔记本软件包……${RESET}" | tee -a "$LOG"
            execute_script "rog.sh"
            ;;
        *)
            echo "未知选项：$option" | tee -a "$LOG"
            ;;
    esac
done

sleep 1
# 如果 arch.png 不存在，则复制 fastfetch 配置
if [ ! -f "$HOME/.config/fastfetch/arch.png" ]; then
    cp -r assets/fastfetch "$HOME/.config/"
fi

clear

# 最后检查必要的软件包是否已安装
execute_script "02-Final-Check.sh"

printf "\n%.0s" {1..1}

# 检查 hyprland 或 hyprland-git 是否已安装
if pacman -Q hyprland &> /dev/null || pacman -Q hyprland-git &> /dev/null; then
    printf "\n ${OK} 👌 Hyprland 已安装。但是，某些必要的软件包可能未安装，请查看上方信息！"
    printf "\n${CAT} 如果上方显示${YELLOW}所有必要软件包${RESET}均已安装，请忽略此消息\n"
    sleep 2
    printf "\n%.0s" {1..2}

    printf "${SKY_BLUE}感谢${RESET} 🫰 您使用 🇵🇭 ${MAGENTA}KooL 的 Hyprland 配置${RESET}。${YELLOW}祝您使用愉快，再见！${RESET}"
    printf "\n%.0s" {1..2}

    printf "\n${NOTE} 您可以通过输入 ${SKY_BLUE}Hyprland${RESET} 启动 Hyprland（如果未安装 SDDM）（注意大写 H！）。\n"
    printf "\n${NOTE} 但是，${YELLOW}强烈建议重启${RESET}您的系统。\n\n"

    while true; do
        echo -n "${CAT} 是否现在重启？(y/n)："
        read HYP
        HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')

        if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
            echo "${INFO} 正在重启……"
            systemctl reboot 
            break
        elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
            echo "👌 ${OK} 您选择了不重启"
            printf "\n%.0s" {1..1}
            # 检查是否存在 NVIDIA GPU
            if lspci | grep -i "nvidia" &> /dev/null; then
                echo "${INFO} 但是 ${YELLOW}检测到 NVIDIA GPU${RESET}。提醒您必须重启系统……"
                printf "\n%.0s" {1..1}
            fi
            break
        else
            echo "${WARN} 无效回复。请回答 'y' 或 'n'。"
        fi
    done
else
    # 如果两个软件包都未安装，则打印错误消息
    printf "\n${WARN} Hyprland 未安装。请检查 00_CHECK-time_installed.log 以及 Install-Logs/ 目录中的其他文件……"
    printf "\n%.0s" {1..3}
    exit 1
fi


printf "\n%.0s" {1..2}
