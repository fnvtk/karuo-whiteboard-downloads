# 卡若智能白板

会议电视上的书写、讨论、AI整理与分享。Windows 一条命令添加独立全屏应用入口；Android 电视可安装 APK。

**会员套餐：月卡¥19.8、年卡¥198、五年卡¥598。应用内微信扫码购买，不自动续费。免费版每块白板可保留1个网址，删除后可换；会员可添加多个网页。AI整理、群分享、隔空书写各有10次免费体验，AI与语音对话及多人协作为会员权益。真实付款到账联动尚待买家验收。**

## Windows 安装

支持 Windows 10/11，需已安装 Edge 或 Chrome。在 PowerShell 中执行：

```powershell
irm https://raw.githubusercontent.com/fnvtk/karuo-whiteboard-downloads/main/install.ps1 | iex
```

桌面和开始菜单会出现“卡若智能白板”，安装完成会自动打开。它是连接线上白板的浏览器独立窗口，需要联网，不是在本机安装服务端。无需管理员权限，不修改防火墙和执行策略。

## Android 会议电视

从本仓库的 [Releases](https://github.com/fnvtk/karuo-whiteboard-downloads/releases) 下载 `karuo-whiteboard-tv.apk`，复制到电视，用文件管理器打开安装。首次安装按电视提示允许本次来源。需要 Android 6 或以上、Google Chrome 和触控屏；隔空书写另需摄像头。

已配置 ADB 的电脑可使用：

```shell
adb install -r karuo-whiteboard-tv.apk
```

APK使用线上最新界面，不必每次网页更新都重装。摄像头首次使用需要你在电视或浏览器中允许访问。

- [第一次使用](docs/01-开始使用.md)
- [书写、协作与AI](docs/02-功能使用.md)
- [会员与免费体验](docs/03-会员与免费体验.md)
- [常见问题与卸载](docs/04-常见问题.md)
- [给AI安装助手的说明](AI/INSTALL.md)

## Windows 给 Android 电视一键安装

电视已开启网络ADB、与电脑同网且已安装Chrome时，在Windows PowerShell执行（把IP换成自己的电视）：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fnvtk/karuo-whiteboard-downloads/main/install.ps1))) -TV -DeviceIP 192.168.1.100
```

脚本只连接指定电视，从Google下载ADB工具，从GitHub下载并校验APK，然后覆盖安装并打开。电视弹出的ADB授权、安装来源及摄像头权限由使用者手动允许。USB连接时可用 `-TV -DeviceId 设备序列号`。

ZIP解压后也可在该目录运行 `./install-local.ps1`。这个入口会正确读取UTF-8编码的安装脚本。
