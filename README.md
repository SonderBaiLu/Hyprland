# 更换默认应用
~/.config/hypr/UserConfigs/01-UserDefaults.conf

🧱 模块一：地基准备（环境初始化）
# 1. 更新系统源并安装 git
sudo pacman -Syu --noconfirm git
# 2. 回到家目录
cd ~
🧱 模块二：拉取
# 克隆配置仓库
git clone https://github.com/SonderBaiLu/Hyprland.git
# 进入到存放安装脚本的模块目录
cd Hyprland/InitScripts/
🧱 模块三：安装
# 1. 赋予主脚本执行权限
chmod +x init.sh
# 2. 启动图形化安装器
./init.sh
🧱 模块四：首次进系统自动精装
重启电脑后，通过登录管理器（SDDM）或在 TTY 终端输入大写的 Hyprland 进入桌面：
1. 触发点火器：系统检测到你的 ~/.config/hypr/ 目录下没有 .initial_startup_done 标记文件。
2. 自动精装：后台会瞬间触发 initial-boot.sh，全自动帮你把当前壁纸送进 wallust 提取配色、渲染 Rofi 主题，并配置好深色模式、GTK 主题和光标。
3. 防线巩固：Startup_Apps.conf 启动，最后一次在后台静默检查 ~/.config/mimeapps.list，确保 Index 永久稳固地接管全局文件夹打开请求。
4. 生成标记：创建标记文件，脚本功成身退，以后开机再也不会重复运行。
