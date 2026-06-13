#!/usr/bin/env bash
# 仅运行一次的初始化脚本，用于在 dotfiles 安装后第一次启动时配置桌面环境
# 此脚本成功执行一次后即可删除！也可以编辑 ~/.config/hypr/configs/Settings.conf 来调整设置
# 由于有标记文件存在，脚本实际上只会运行一次，因此不删除也没关系
# 标记文件位于 ~/.config/hypr/.initial_startup_done
# 强烈建议不要手动触碰该标记文件，只要它存在，脚本就不会再次运行

# 定义常用目录和文件路径变量
scriptsDir=$HOME/.config/hypr/scripts                      # 脚本目录
wallpaper=$HOME/.config/hypr/wallpaper_effects/.wallpaper_current  # 当前壁纸文件
# 各主题配置变量
waybar_style="$HOME/.config/waybar/style/[Extra] Neon Circuit.css" # Waybar 样式文件
kvantum_theme="catppuccin-mocha-blue"                     # Kvantum 主题名
color_scheme="prefer-dark"                                # GTK 颜色方案（偏好深色）
gtk_theme="Flat-Remix-GTK-Blue-Dark"                      # GTK 主题
icon_theme="Flat-Remix-Blue-Dark"                         # 图标主题
cursor_theme="Bibata-Modern-Ice"                          # 光标主题

# 壁纸切换命令及过渡效果参数
swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 30 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# 检查标记文件是否不存在（即从未运行过此脚本）
if [ ! -f "$HOME/.config/hypr/.initial_startup_done" ]; then
    sleep 1   # 等待1秒，确保其他服务（如 swww-daemon）已启动

    # 初始化 wallust（配色生成器）和壁纸
    if [ -f "$wallpaper" ]; then                          # 如果壁纸文件存在
        wallust run -s $wallpaper > /dev/null             # 以静默模式运行 wallust，基于当前壁纸生成色彩方案
        swww query || swww-daemon && $swww $wallpaper $effect  # 若 swww 守护进程未运行则启动，然后设置壁纸和过渡效果
        "$scriptsDir/WallustSwww.sh" > /dev/null 2>&1 &   # 后台执行额外脚本，更新更多壁纸相关配置
    fi
     
    # 设置 GTK 主题为深色模式，并应用图标和光标主题（适用于大多数发行版）
    gsettings set org.gnome.desktop.interface color-scheme $color_scheme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme $icon_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &

    # NixOS 下特殊处理：使用 dconf 和带引号的 gsettings 语法设置 GTK 主题
    if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'$color_scheme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/icon-theme "'$icon_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/cursor-theme "'$cursor_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/cursor-size "24" > /dev/null 2>&1 &
    fi
       
    # 设置 Kvantum 主题（用于 Qt 应用外观）
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &
    # 创建标记文件，表示首次启动初始化已完成
    touch "$HOME/.config/hypr/.initial_startup_done"

    exit
fi
