$ErrorActionPreference = "Stop"

$taskName = "CopilotApiService"
$projectDir = $PSScriptRoot
$logDir = Join-Path $env:LOCALAPPDATA "copilot-proxy\logs"
$userId = if ($env:USERDOMAIN) { "$($env:USERDOMAIN)\$($env:USERNAME)" } else { $env:USERNAME }
$restartCount = 3

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$command = "cd /d `"$projectDir`" && npx copilot-api start >> `"$logDir\copilot-api.log`" 2>>&1"
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$command`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount $restartCount -RestartInterval (New-TimeSpan -Minutes 1)

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Run copilot-api on startup" | Out-Null
Start-ScheduledTask -TaskName $taskName

Write-Host "✅ Scheduled task '$taskName' created and started."
Write-Host "Logs available at: $logDir\copilot-api.log"
