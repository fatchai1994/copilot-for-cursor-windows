$ErrorActionPreference = "Stop"

$taskName = "CopilotProxyService"
$projectDir = $PSScriptRoot
$logDir = Join-Path $env:LOCALAPPDATA "copilot-proxy\logs"
$userId = if ($env:USERDOMAIN) { "$($env:USERDOMAIN)\$($env:USERNAME)" } else { "$($env:COMPUTERNAME)\$($env:USERNAME)" }
$restartCount = 3

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$logPath = Join-Path $logDir "copilot-proxy.log"
$escapedProjectDir = $projectDir -replace "'", "''"
$escapedLogPath = $logPath -replace "'", "''"
$command = "Set-Location -LiteralPath '$escapedProjectDir'; bun run proxy-router.ts *>> '$escapedLogPath'"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount $restartCount -RestartInterval (New-TimeSpan -Minutes 1)

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Run Copilot proxy router on startup" | Out-Null
Start-ScheduledTask -TaskName $taskName

Write-Host "✅ Scheduled task '$taskName' created and started."
Write-Host "Logs available at: $logPath"
