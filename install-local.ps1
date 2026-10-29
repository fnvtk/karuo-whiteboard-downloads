param([switch]$Uninstall, [switch]$TV, [string]$DeviceIP, [string]$DeviceId)
$ScriptPath = Join-Path $PSScriptRoot 'install.ps1'
$ScriptText = [System.IO.File]::ReadAllText($ScriptPath, [System.Text.Encoding]::UTF8)
& ([scriptblock]::Create($ScriptText)) @PSBoundParameters
