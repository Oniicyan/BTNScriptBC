Remove-Variable * -ErrorAction Ignore
if ((Fltmc).Count -eq 3) {
	$APPWTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
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

# 名称变更，此部分保留一段时间
$OLDPATH = "$ENV:USERPROFILE\BTN_BC"
$NEWPATH = "$ENV:USERPROFILE\BTNScriptBC"
if (Test-Path $NEWPATH) {
	Remove-Item $OLDPATH -Force -ErrorAction Ignore
} else {
	Move-Item $OLDPATH $NEWPATH -Force -ErrorAction Ignore
}
if ($OLDLIST = (Get-NetFirewallRule -DisplayName BTN_* | Get-NetFirewallApplicationFilter).Program | Sort-Object | Get-Unique) {
	$DYKWID = "{da62ac48-4707-4adf-97ea-676470a460f5}"
	foreach ($APPPATH in $OLDLIST) {
		$APPNAME = [System.IO.Path]::GetFileName($APPPATH)
		New-NetFirewallRule -DisplayName "BTNScript_$APPNAME" -Direction Inbound -Action Block -Program $APPPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
		New-NetFirewallRule -DisplayName "BTNScript_$APPNAME" -Direction Outbound -Action Block -Program $APPPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	}
	Remove-NetFirewallRule -DisplayName BTN_*
}
if ($OLDTASK = Get-ScheduledTask BTN_BC_STARTUP -ErrorAction Ignore) {
	$NEWTASK = New-ScheduledTask -Principal $OLDTASK.Principal -Settings $OLDTASK.Settings -Trigger $OLDTASK.Triggers -Action $OLDTASK.Actions
	Unregister-ScheduledTask BTN_BC_STARTUP -Confirm:$false -ErrorAction Ignore
	Register-ScheduledTask BTNScriptBC_STARTUP -InputObject $NEWTASK | Out-Null
}
Set-ScheduledTask BTNScriptBC_STARTUP -Action (New-ScheduledTaskAction -Execute "$NEWPATH\STARTUP.cmd") -ErrorAction Ignore | Out-Null

Get-Item $ENV:TEMP\BTNScriptBC_* | ForEach-Object {
	Stop-Process ($_.Name -Split '_')[-1] -Force -ErrorAction Ignore
	Remove-Item $_
}

if ($RULELIST = Get-NetFirewallRule -DisplayName BTNScript_*) {
	Write-Host "`n  清除以下过滤规则`n"
	$RULELIST | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
	Write-Host
	pause
	Remove-NetFirewallRule $RULELIST
} else {
	Write-Host "`n  没有需要清除的过滤规则`n"
}

if ($TASKLIST = Get-ScheduledTask BTNScriptBC_*) {
	Write-Host "`n  清除以下任务计划`n"
	$TASKLIST.TaskName | ForEach-Object {'  ' + $_}
	Write-Host
	pause
	Unregister-ScheduledTask $TASKLIST.TaskName -Confirm:$false
} else {
	Write-Host "`n  没有需要清除的任务计划`n"
}

$GUID = '{da62ac48-4707-4adf-97ea-676470a460f5}'
if ($DYKW = Get-NetFirewallDynamicKeywordAddress -Id $GUID -ErrorAction Ignore) {
	Write-Host "`n  清除以下动态关键字`n"
	$DYKW.Keyword | ForEach-Object {'  ' + $_}
	Write-Host
	pause
	Remove-NetFirewallDynamicKeywordAddress -Id $GUID
} else {
	Write-Host "`n  没有需要清除的动态关键字`n"
}

if (Test-Path $ENV:USERPROFILE\BTNScriptBC) {
	Write-Host "`n  清除以下脚本文件`n"
	Write-Host "  $ENV:USERPROFILE\BTNScriptBC"
	(Get-Childitem $ENV:USERPROFILE\BTNScriptBC -Recurse).FullName | ForEach-Object {'  ' + $_}
	Write-Host
	pause
	Remove-Item $ENV:USERPROFILE\BTNScriptBC -Force -Recurse -ErrorAction Ignore
} else {
	Write-Host "`n  没有需要清除的脚本文件`n"
}

Write-Host "`n  已清除所有配置`n"
Read-Host 操作完成，按 Enter 键结束...
