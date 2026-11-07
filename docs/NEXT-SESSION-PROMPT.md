# 新会话启动 Prompt（mtgpu-pegasus）

把下面整段贴进新会话即可直接开工。

---

你是运行在 DeepSeek Harness 里的编码代理。本会话的目标：在
**Ubuntu 24.04 ARM64 + 摩尔线程 M1000（MTGPU）** 上把
[Pegasus Frontend](https://pegasus-frontend.org) 跑起来，并做成可用的模拟器集合前端。

## 机器与环境

- 目标机：内网 aarch64 主机（SSH key `~/.ssh/id_ed25519_aibook`，sudo 免密；地址见本地 SSH 配置）；
- aarch64，KDE Plasma 6 Wayland（`:0`），独立 Xorg `:3` 可按需启动；
- 显示原生 2880×1800@120；Game Mode 用 1280×720@59.97；
- 已有工作：
  - `/root/lvllm/repos/mtgpu-steam-fex`：Steam arm64 + FEX + Proton ARM64、`M1000ARM64` 兼容工具、
    Game Mode、独立 Xorg 配置（`/opt/steamos`）；
  - `/root/lvllm/repos/reunion-lite`：红警2 启动器（0.2 已支持 Linux arm64）；
  - 目标机 `~/.local/share/m1000/work/` 是运行目录（禁止用 `/tmp`）。

## 已知事实（Pegasus）

- 上游：`https://github.com/mmatyas/pegasus-frontend`，最新稳定 `weekly_2024w38`（alpha16-82），
  continuous build 更新到 alpha16-112；
- 官方 **没有 aarch64 桌面构建**：`x11-static.zip`/`deb` 是 x86_64；`rpi4-static.zip` 是
  armhf（32 位，`ld-linux-armhf.so.3`），aarch64 桌面无法直接运行；
- 支持 Qt5.15 / Qt6（CMake `find_package(Qt6 ...)` 优先），必需组件：
  Core、Qml、Quick、QuickCompiler、QmlImportScanner、Multimedia、Sql、Svg、LinguistTools；
  可选 SDL2（手柄/电量）；GStreamer 1.x 用于视频；
- 配置目录 `~/.config/pegasus-frontend/`：`game_dirs.txt`、`metafiles/*.metadata.pegasus.txt`、
  `settings.txt`；每个平台上可用 `{file.path}` 作为启动命令参数。

## 任务（按顺序）

1. **构建**：在目标机装齐 Qt6 QML/Multimedia/Sql/Svg 开发包、SDL2、GStreamer（先用
   `apt-get -s install` 评估，遵守“纯新增”纪律），从源码 CMake 构建 aarch64 `pegasus-fe`；
   记录完整依赖清单与命令。
2. **运行验证**：先在 `:0`（KDE Wayland）跑起来，截图为证；若 QML/OpenGL 有问题，
   用独立 Xorg `:3`（参考 mtgpu-steam-fex 的 `config/xorg-m1000.conf`）对比。
3. **配置模板**：在仓库里提供 `config/` 模板（`game_dirs.txt`、示例 metadata、`settings.txt`），
   写 `install.sh` 把二进制 + 配置装进用户目录。
4. **接入游戏**：
   - 用 RetroArch（若已装）验证一个 ROM 的扫描与启动；
   - 从 `steamapps` 生成 Steam 游戏元数据，点击后用 `steam -applaunch <appid>` 启动；
   - 加一条红警2 条目，调用 `/root/lvllm/repos/reunion-lite/scripts/linux/ra2-launch.sh`。
5. **体验与打包**：Game Mode 720p、手柄映射、开机自启（systemd user unit），
   最后 `git push` 到 `yeungtuzi/mtgpu-pegasus` 并更新 README 截图。

## 纪律

- 中文、简洁、不吹；没验证的不说成验证过；
- 不 `pkill -f`（用 `pkill -x` / `pgrep -f "foo[-]bar"`）；
- 不在 `/tmp` 放工作产物，统一 `~/.local/share/m1000/work/`；
- apt 只装纯新增包，先 `-s` 评估；系统级写入登记 manifest；
- 截图：KDE 用 `/opt/kde6/bin/spectacle -b -n -f -o out.png`，Xorg `:3` 用
  `DISPLAY=:3 import -window root`；同一张图不重复读；
- 破坏性操作（删文件、改系统配置）先确认；
- 提交前清理敏感信息（内网地址、账号）。
