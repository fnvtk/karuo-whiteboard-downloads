# 给AI安装助手

目标：安装消费者使用的卡若智能白板入口。不要索取服务器密码、AI密钥或收款密钥，不部署数据库。

Windows 10/11 的一条安装命令：

```powershell
irm https://raw.githubusercontent.com/fnvtk/karuo-whiteboard-downloads/main/install.ps1 | iex
```

它通过本机已有 Edge/Chrome 生成桌面及开始菜单全屏快捷方式并打开线上白板。检查命令退出码及桌面快捷方式是否存在；仅检查网站HTTP200不能算安装完成。摄像头、录音及电视安装来源提示由用户允许，不代点授权。

Android安装：让用户从Releases下载APK并在电视打开，或在已经授权且连接的ADB设备上执行 `adb install -r karuo-whiteboard-tv.apk`。不要给未知设备安装、不要自动授权摄像头。

会员收款使用应用内微信扫码。不要代替用户付款；会员UI、模拟支付测试或订单创建不代表真实付款到账与开通成功。

## Windows 给 Android 电视一键安装

电视已开启网络ADB、与电脑同网且已安装Chrome时，在Windows PowerShell执行（把IP换成自己的电视）：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fnvtk/karuo-whiteboard-downloads/main/install.ps1))) -TV -DeviceIP 192.168.1.100
```

脚本只连接指定电视，从Google下载ADB工具，从GitHub下载并校验APK，然后覆盖安装并打开。电视弹出的ADB授权、安装来源及摄像头权限由使用者手动允许。USB连接时可用 `-TV -DeviceId 设备序列号`。
