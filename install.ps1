param([switch]$Uninstall, [switch]$TV, [string]$DeviceIP, [string]$DeviceId)
# Decode UI text explicitly for Windows PowerShell 5.1 remote execution.
function Get-WhiteboardText([string]$Value) { [System.Text.RegularExpressions.Regex]::Unescape($Value) }
$ErrorActionPreference = 'Stop'
$AppDirectory = Join-Path $env:LOCALAPPDATA 'KaruoWhiteboard'
$DesktopLink = Join-Path ([Environment]::GetFolderPath('Desktop')) (Get-WhiteboardText '\u5361\u82e5\u667a\u80fd\u767d\u677f.lnk')
$StartLink = Join-Path ([Environment]::GetFolderPath('Programs')) (Get-WhiteboardText '\u5361\u82e5\u667a\u80fd\u767d\u677f.lnk')
if ($Uninstall -and -not $TV) {
    foreach ($Link in @($DesktopLink,$StartLink)) { if (Test-Path -LiteralPath $Link) { Remove-Item -LiteralPath $Link -Force } }
    if (Test-Path $AppDirectory) { Remove-Item -LiteralPath $AppDirectory -Recurse -Force }
    Write-Host (Get-WhiteboardText '\u5df2\u79fb\u9664\u767d\u677f\u5feb\u6377\u65b9\u5f0f\uff1b\u6d4f\u89c8\u5668\u4e2d\u7684\u4f1a\u8bae\u6570\u636e\u548c\u8d26\u53f7\u4fdd\u6301\u3002')
    return
}
if ($TV) {
    if ($Uninstall) { throw (Get-WhiteboardText '\u7535\u89c6\u5378\u8f7d\u8bf7\u5728\u7535\u89c6\u7684\u7cfb\u7edf\u5e94\u7528\u8bbe\u7f6e\u4e2d\u8fdb\u884c\u3002') }
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
        if (-not [Net.IPAddress]::TryParse($DeviceIP, [ref]$ParsedAddress)) { throw (Get-WhiteboardText 'DeviceIP \u8bf7\u586b\u5199\u7535\u89c6\u7684IP\u5730\u5740\uff0c\u4e0d\u5305\u542b\u7aef\u53e3\u3002') }
        $DeviceId = "${DeviceIP}:5555"
        & $Adb connect $DeviceId
        if ($LASTEXITCODE -ne 0) { throw (Get-WhiteboardText '\u65e0\u6cd5\u8fde\u63a5\u7535\u89c6\uff0c\u8bf7\u786e\u8ba4\u7535\u89c6\u5df2\u5f00\u542f\u7f51\u7edcADB\u4e14\u4e0e\u7535\u8111\u5728\u540c\u4e00\u7f51\u7edc\u3002') }
    }
    if (-not $DeviceId) {
        $Devices = @(& $Adb devices | Select-String '^([^\s]+)\s+device$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
        if ($Devices.Count -ne 1) { throw (Get-WhiteboardText '\u8bf7\u53ea\u8fde\u63a5\u4e00\u53f0\u5df2\u6388\u6743\u7535\u89c6\uff0c\u6216\u7528 -DeviceId \u6307\u5b9a\u8bbe\u5907\u3002\u82e5\u7535\u89c6\u5f39\u51faADB\u6388\u6743\uff0c\u8bf7\u5148\u624b\u52a8\u5141\u8bb8\u3002') }
        $DeviceId = $Devices[0]
    }
    $Chrome = & $Adb -s $DeviceId shell pm path com.android.chrome
    if ($LASTEXITCODE -ne 0 -or -not ($Chrome -match 'package:')) { throw (Get-WhiteboardText '\u7535\u89c6\u9700\u8981\u5148\u5b89\u88c5Google Chrome\u3002\u8bf7\u901a\u8fc7\u7535\u89c6\u7684\u5e94\u7528\u5546\u5e97\u6216\u7ba1\u7406\u5458\u5b89\u88c5\u540e\u518d\u8fd0\u884c\u3002') }
    $Apk = Join-Path $AppDirectory 'karuo-whiteboard-tv.apk'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/fnvtk/karuo-whiteboard-downloads/releases/download/v2026.10.29-preview/karuo-whiteboard-tv.apk' -OutFile $Apk
    $ExpectedHash = '670144a40fa15b8813beb377509cb403922bcafa05df3038b09f6db692653081'
    if ((Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) { throw (Get-WhiteboardText '\u5b89\u88c5\u5305\u6821\u9a8c\u5931\u8d25\uff0c\u5df2\u505c\u6b62\u5b89\u88c5\u3002') }
    & $Adb -s $DeviceId install -r $Apk
    if ($LASTEXITCODE -ne 0) { throw (Get-WhiteboardText '\u7535\u89c6\u5b89\u88c5\u5931\u8d25\uff0c\u8bf7\u4fdd\u7559\u9519\u8bef\u4fe1\u606f\u4ea4\u7ed9\u7ba1\u7406\u5458\uff1b\u4e0d\u8981\u76f4\u63a5\u6e05\u9664\u539f\u6709\u6570\u636e\u3002') }
    & $Adb -s $DeviceId shell am start -n tv.whiteboard.launcher/.MainActivity
    if ($LASTEXITCODE -ne 0) { throw (Get-WhiteboardText 'APK\u5df2\u5b89\u88c5\uff0c\u4f46\u672a\u80fd\u6253\u5f00\uff0c\u8bf7\u5728\u7535\u89c6\u4e0a\u624b\u52a8\u6253\u5f00\u5361\u82e5\u667a\u80fd\u767d\u677f\u3002') }
    Write-Host (Get-WhiteboardText '\u7535\u89c6\u5b89\u88c5\u5b8c\u6210\uff0c\u5df2\u6253\u5f00\u5361\u82e5\u667a\u80fd\u767d\u677f\u3002\u6444\u50cf\u5934\u6388\u6743\u9700\u8981\u4f60\u5728\u7535\u89c6\u4e0a\u5141\u8bb8\u3002')
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
if (-not $Browser) { throw (Get-WhiteboardText '\u8bf7\u5148\u5b89\u88c5 Microsoft Edge \u6216 Google Chrome\uff0c\u518d\u91cd\u65b0\u8fd0\u884c\u672c\u547d\u4ee4\u3002') }
New-Item -ItemType Directory -Path $AppDirectory -Force | Out-Null
$Arguments = '--app=https://wz_wb.quwanzhi.com/?compat=modern --start-fullscreen'
$Shell = New-Object -ComObject WScript.Shell
foreach ($Link in @($DesktopLink,$StartLink)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Link) -Force | Out-Null
    $Shortcut = $Shell.CreateShortcut($Link)
    $Shortcut.TargetPath = $Browser
    $Shortcut.Arguments = $Arguments
    $Shortcut.Description = (Get-WhiteboardText '\u5361\u82e5\u667a\u80fd\u767d\u677f \u00b7 \u4f1a\u8bae\u3001AI\u6574\u7406\u4e0e\u56e2\u961f\u534f\u4f5c')
    $Shortcut.WorkingDirectory = $AppDirectory
    $Shortcut.Save()
}
@{ Product=(Get-WhiteboardText '\u5361\u82e5\u667a\u80fd\u767d\u677f'); Version='2026.10.29-preview'; Website='https://wz_wb.quwanzhi.com'; Type='HostedWebApp' } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $AppDirectory 'install.json') -Encoding UTF8
Write-Host (Get-WhiteboardText '\u5b89\u88c5\u5b8c\u6210\uff1a\u684c\u9762\u548c\u5f00\u59cb\u83dc\u5355\u5df2\u6dfb\u52a0\u201c\u5361\u82e5\u667a\u80fd\u767d\u677f\u201d\u3002\u65e0\u9700\u7ba1\u7406\u5458\u6743\u9650\u3002')
Start-Process -FilePath $Browser -ArgumentList $Arguments
