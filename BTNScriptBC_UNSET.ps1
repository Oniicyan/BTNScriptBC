if ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限重新执行"
	echo ""
	pause
	exit
}

$RULELIST = Get-NetFirewallRule -DisplayName BTN_* | Select-Object -Property Displayname, Direction
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

$TASKLIST = (Get-ScheduledTask BTN_BC_*).TaskName
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

$FILELIST = (Get-Childitem $env:USERPROFILE\BTN_BC -Recurse).FullName
if ($FILELIST) {
	echo ""
	echo "  清除以下脚本文件"
	echo ""
	echo "  $env:USERPROFILE\BTN_BC"
	$FILELIST | ForEach-Object {'  ' + $_}
	echo ""
	pause
	Remove-Item $env:USERPROFILE\BTN_BC -Force -Recurse -ErrorAction Ignore
} else {
	echo ""
	echo "  没有需要清除的脚本文件"
}

echo ""
echo "  已清除所有配置"
echo ""
