param([switch]$Uninstall, [switch]$TV, [string]$DeviceIP, [string]$DeviceId)
$ErrorActionPreference = 'Stop'
$AppDirectory = Join-Path $env:LOCALAPPDATA 'KaruoWhiteboard'
$DesktopLink = Join-Path ([Environment]::GetFolderPath('Desktop')) '卡若智能白板.lnk'
$StartLink = Join-Path ([Environment]::GetFolderPath('Programs')) '卡若智能白板.lnk'
if ($Uninstall -and -not $TV) {
    foreach ($Link in @($DesktopLink,$StartLink)) { if (Test-Path -LiteralPath $Link) { Remove-Item -LiteralPath $Link -Force } }
    if (Test-Path $AppDirectory) { Remove-Item -LiteralPath $AppDirectory -Recurse -Force }
    Write-Host '已移除白板快捷方式；浏览器中的会议数据和账号保持。'
    return
}
if ($TV) {
    if ($Uninstall) { throw '电视卸载请在电视的系统应用设置中进行。' }
    $ToolsDirectory = Join-Path $AppDirectory 'platform-tools'
    $Adb = Join-Path $ToolsDirectory 'adb.exe'
    New-Item -ItemType Directory -Path $AppDirectory -Force | Out-Null
    if (-not (Test-Path $Adb)) {
        $ToolsZip = Join-Path $AppDirectory 'platform-tools.zip'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $ToolsZip
        Expand-Archive -LiteralPath $ToolsZip -DestinationPath $AppDirectory -Force
        Remove-Item -LiteralPath $ToolsZip
    }
    if ($DeviceIP) {
        $ParsedAddress = $null
        if (-not [Net.IPAddress]::TryParse($DeviceIP, [ref]$ParsedAddress)) { throw 'DeviceIP 请填写电视的IP地址，不包含端口。' }
        $DeviceId = "${DeviceIP}:5555"
        & $Adb connect $DeviceId
        if ($LASTEXITCODE -ne 0) { throw '无法连接电视，请确认电视已开启网络ADB且与电脑在同一网络。' }
    }
    if (-not $DeviceId) {
        $Devices = @(& $Adb devices | Select-String '^([^\s]+)\s+device$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
        if ($Devices.Count -ne 1) { throw '请只连接一台已授权电视，或用 -DeviceId 指定设备。若电视弹出ADB授权，请先手动允许。' }
        $DeviceId = $Devices[0]
    }
    $Chrome = & $Adb -s $DeviceId shell pm path com.android.chrome
    if ($LASTEXITCODE -ne 0 -or -not ($Chrome -match 'package:')) { throw '电视需要先安装Google Chrome。请通过电视的应用商店或管理员安装后再运行。' }
    $Apk = Join-Path $AppDirectory 'karuo-whiteboard-tv.apk'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/fnvtk/karuo-whiteboard-downloads/releases/download/v2026.10.29-preview/karuo-whiteboard-tv.apk' -OutFile $Apk
    $ExpectedHash = '670144a40fa15b8813beb377509cb403922bcafa05df3038b09f6db692653081'
    if ((Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) { throw '安装包校验失败，已停止安装。' }
    & $Adb -s $DeviceId install -r $Apk
    if ($LASTEXITCODE -ne 0) { throw '电视安装失败，请保留错误信息交给管理员；不要直接清除原有数据。' }
    & $Adb -s $DeviceId shell am start -n tv.whiteboard.launcher/.MainActivity
    if ($LASTEXITCODE -ne 0) { throw 'APK已安装，但未能打开，请在电视上手动打开卡若智能白板。' }
    Write-Host '电视安装完成，已打开卡若智能白板。摄像头授权需要你在电视上允许。'
    return
}
$BrowserCandidates = @()
foreach ($RootDirectory in @(${env:ProgramFiles(x86)},$env:ProgramFiles,$env:LOCALAPPDATA)) {
    if ($RootDirectory) {
        $BrowserCandidates += Join-Path $RootDirectory 'Microsoft\Edge\Application\msedge.exe'
        $BrowserCandidates += Join-Path $RootDirectory 'Google\Chrome\Application\chrome.exe'
    }
}
$Browser = $BrowserCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Browser) { throw '请先安装 Microsoft Edge 或 Google Chrome，再重新运行本命令。' }
New-Item -ItemType Directory -Path $AppDirectory -Force | Out-Null
$Arguments = '--app=https://wz_wb.quwanzhi.com/?compat=modern --start-fullscreen'
$Shell = New-Object -ComObject WScript.Shell
foreach ($Link in @($DesktopLink,$StartLink)) {
    $Shortcut = $Shell.CreateShortcut($Link)
    $Shortcut.TargetPath = $Browser
    $Shortcut.Arguments = $Arguments
    $Shortcut.Description = '卡若智能白板 · 会议、AI整理与团队协作'
    $Shortcut.WorkingDirectory = $AppDirectory
    $Shortcut.Save()
}
@{ Product='卡若智能白板'; Version='2026.10.29-preview'; Website='https://wz_wb.quwanzhi.com'; Type='HostedWebApp' } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $AppDirectory 'install.json') -Encoding UTF8
Write-Host '安装完成：桌面和开始菜单已添加“卡若智能白板”。无需管理员权限。'
Start-Process -FilePath $Browser -ArgumentList $Arguments
