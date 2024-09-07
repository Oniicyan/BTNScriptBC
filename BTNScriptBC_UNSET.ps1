if ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限重新执行"
	echo ""
	pause
	exit
}

# 名称变更，此部分保留一段时间
$OLDPATH = "$ENV:USERPROFILE\BTN_BC"
$NEWPATH = "$ENV:USERPROFILE\BTNScriptBC"
if (Test-Path $NEWPATH) {
	Remove-Item $OLDPATH -Force -ErrorAction Ignore
} else {
	Move-Item $OLDPATH $NEWPATH -Force -ErrorAction Ignore
}
Get-NetFirewallRule -DisplayName BTN_* |% {Set-NetFirewallRule $_.Name -NewDisplayName $_.DisplayName.Replace('BTN_','BTNScript_')}
if ($OLDTASK = Get-ScheduledTask BTN_BC_STARTUP) {
	$NEWTASK = New-ScheduledTask -Principal $OLDTASK.Principal -Settings $OLDTASK.Settings -Trigger $OLDTASK.Triggers -Action $OLDTASK.Actions
	Unregister-ScheduledTask BTN_BC_STARTUP -Confirm:$false -ErrorAction Ignore
	Register-ScheduledTask BTNScriptBC_STARTUP -InputObject $NEWTASK | Out-Null
}

$RULELIST = Get-NetFirewallRule -DisplayName BTNScript_* | Select-Object -Property Displayname, Direction
if ($RULELIST) {
	echo ""
	echo "  清除以下过滤规则"
	echo ""
	$RULELIST | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
	echo ""
	pause
	Remove-NetFirewallRule -DisplayName $RULELIST.DisplayName
} else {
	echo ""
	echo "  没有需要清除的过滤规则"
}

$TASKLIST = (Get-ScheduledTask BTNScriptBC_*).TaskName
if ($TASKLIST) {
	echo ""
	echo "  清除以下任务计划"
	echo ""
	$TASKLIST | ForEach-Object {'  ' + $_}
	echo ""
	pause
	Unregister-ScheduledTask $TASKLIST -Confirm:$false
} else {
	echo ""
	echo "  没有需要清除的任务计划"
}

$DYKWID = "{da62ac48-4707-4adf-97ea-676470a460f5}"
if ($DYKWNAME = (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore).Keyword) {
	echo ""
	echo "  清除以下动态关键字"
	echo ""
	$DYKWNAME | ForEach-Object {'  ' + $_}
	echo ""
	pause
	Remove-NetFirewallDynamicKeywordAddress -Id $DYKWID
} else  {
	echo ""
	echo "  没有需要清除的动态关键字"
}

$FILELIST = (Get-Childitem $env:USERPROFILE\BTNScriptBC -Recurse).FullName
if ($FILELIST) {
	echo ""
	echo "  清除以下脚本文件"
	echo ""
	echo "  $env:USERPROFILE\BTNScriptBC"
	$FILELIST | ForEach-Object {'  ' + $_}
	echo ""
	pause
	Remove-Item $env:USERPROFILE\BTNScriptBC -Force -Recurse -ErrorAction Ignore
} else {
	echo ""
	echo "  没有需要清除的脚本文件"
}

echo ""
echo "  已清除所有配置"
echo ""
