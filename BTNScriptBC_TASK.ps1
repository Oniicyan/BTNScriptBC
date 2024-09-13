$USERPATH = "$ENV:USERPROFILE\BTNScriptBC"
if (!(Test-Path $USERPATH\STARTUP.cmd)) {Write-Host `n  未配置 BTNScriptBC`n; return}
if ((Fltmc).Count -eq 3) {
	if (Test-Path $APPWTPATH) {
		$PROCESS = "$APPWTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
	} else {
		$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
	}
	Write-Host "`n  10 秒后以管理员权限继续执行"
	timeout 10
	Invoke-Expression "Start-Process $PROCESS -Verb RunAs"
	return
}
$PRINCIPAL = New-ScheduledTaskPrincipal -UserId $ENV:COMPUTERNAME\$ENV:USERNAME -RunLevel Highest
$SETTINGS = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -AllowStartIfOnBatteries
$TRIGGER = New-ScheduledTaskTrigger -AtLogon -User $ENV:COMPUTERNAME\$ENV:USERNAME
$ACTION = New-ScheduledTaskAction -Execute "$USERPATH\STARTUP.cmd"
$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION
Unregister-ScheduledTask BTNScriptBC_STARTUP -Confirm:$false -ErrorAction Ignore
Register-ScheduledTask BTNScriptBC_STARTUP -InputObject $TASK | Out-Null
Write-Host "`n  已配置自启动任务计划：BTNScriptBC_STARTUP`n"
