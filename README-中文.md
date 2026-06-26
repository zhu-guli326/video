# Screen Studio Lite for OBS 分享包

这是一个 Windows OBS Lua 脚本包，用来做类似 Screen Studio 的录屏效果：竖屏 3:4、点击自动放大、打字自动放大、鼠标样式、背景卡片、圆角画面和高清录制预设。

## 功能

- 默认 3:4 竖屏画布：`2160 x 2880`
- 高清录制：60 FPS、Lanczos 缩放、高码率 NVENC 默认配置
- 点击放大：默认 `2.0x`
- 打字放大：默认 `2.6x`，会跟随输入光标
- 放大时支持上下跟随，避免屏幕底部录不到
- 鼠标样式、点击反馈、圆角遮罩、纯色背景卡片
- 安装时自动开启 `HideOBSWindowsFromCapture=true`，避免 OBS 套 OBS 乱码

## 安装方法

1. 先关闭 OBS。
2. 下载或克隆这个仓库。
3. 双击 `install-windows.cmd`。
4. 打开 OBS。
5. 进入 `工具 > 脚本`。
6. 如果列表里没有 `screen-studio-lite.lua`，手动添加：
   `%APPDATA%\obs-studio\scripts\screen-studio-lite.lua`
7. 在脚本面板里点击 `Create Full Studio Setup`。

## 使用建议

- OBS 弹出“安全模式”时，选择正常启动；安全模式会禁用脚本。
- 录制时尽量把 OBS 最小化或放到另一个屏幕。
- 可以在脚本设置里调：
  - `Auto Click Zoom Scale`
  - `Typing Zoom Scale`
  - `Auto Click Reset Delay`
  - `Smooth Zoom Duration`
  - `Recording Aspect Preset`

## 卸载

关闭 OBS 后，双击 `uninstall-windows.cmd`。

## 注意

安装脚本只复制脚本和资源到 OBS 的 scripts 文件夹，不会覆盖你的 OBS 场景集合。
