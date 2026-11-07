# mtgpu-pegasus

在 **Ubuntu 24.04 ARM64 + 摩尔线程 M1000（MTGPU）** 上跑
[Pegasus Frontend](https://pegasus-frontend.org) 模拟器集合前端的方案与构建脚本。

目标：把散落在各处的模拟器（RetroArch / PPSSPP / Dolphin / DuckStation / MAME …）
和原生游戏（Steam、Reunion Lite 等）收进一个可手柄操作的全屏界面，
在这台国产 GPU 的 ARM64 机器上开箱即用。

## 状态

进行中：仓库刚建立，正在打通 aarch64 构建与 M1000 上的显示/输入。

## 为什么需要单独做

- Pegasus 官方 release **没有通用 aarch64 桌面构建**：`x11-static.zip` / `.deb` 是 x86_64，
  `rpi4-static.zip` 是 **armhf（32 位 ARM）**，在 aarch64 桌面上跑不了；
- 因此需要在目标机上从源码构建（Qt6 + SDL2 + GStreamer），并验证 QML 在
  M1000 / KDE Wayland 下的显示与性能；
- 还需要把现有工作接进来：`mtgpu-steam-fex`（Steam/FEX/Proton）、
  `reunion-lite`（红警2 启动器）、以及本机已装的模拟器。

## 计划

1. **构建**：Qt6（Core/Qml/Quick/Multimedia/Sql/Svg）+ SDL2 + GStreamer，CMake 构建 aarch64 二进制；
2. **运行**：在 KDE Wayland（`:0`）与独立 Xorg（`:3`）两种显示下验证，确定推荐路径；
3. **配置**：`~/.config/pegasus-frontend/` 的 `game_dirs.txt` / `metafiles/` / `settings.txt`，
   写一套可提交的配置模板；
4. **接入**：
   - 模拟器：RetroArch（libretro cores）、PPSSPP、Dolphin、DuckStation 等，按已装情况接入；
   - Steam：从 `steamapps` 生成 metadata（或调用 `steam -applaunch`）；
   - 红警2：调用 Reunion Lite 的 `ra2-launch.sh`；
5. **体验**：Game Mode（720p@60）+ 手柄（Super/键盘映射）、主题、开机自启；
6. **打包**：`install.sh` + 可选的 `.deb`/tar.gz，与 `mtgpu-steam-fex` 的 `/opt/steamos` 隔离风格一致。

## 相关

- [Pegasus Frontend](https://pegasus-frontend.org)（[源码](https://github.com/mmatyas/pegasus-frontend)，alpha16，Qt5/Qt6）
- [mtgpu-steam-fex](https://github.com/yeungtuzi/mtgpu-steam-fex)：本机 Steam + FEX + Proton 方案
- [reunion-lite](https://github.com/yeungtuzi/reunion-lite)：红警2 启动器

## License

MIT（本仓库脚本与文档）。Pegasus 本身为 MIT。
