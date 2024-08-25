Remove-Variable * -ErrorAction Ignore

if ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限执行"
	echo ""
	return
}

$TESTGUID = "{62809d89-9d3b-486b-808f-8c893c1c3378}"
Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID -ErrorAction Ignore
if (New-NetFirewallDynamicKeywordAddress -Id $TESTGUID -Keyword "BT_BAN_TEST" -Address 1.2.3.4 -ErrorAction Ignore) {
	Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID
} else {
	echo ""
	echo "  当前 Windows 版本不支持动态关键字，请升级操作系统"
	echo ""
	echo "  如不使用过滤规则，仅提交 Peers 列表至 BTN，请执行以下命令"
	echo ""
	echo "  iex (irm btn-bc.pages.dev/nofw)"
	echo ""
	return
}

if ((Get-NetFirewallProfile).Enabled -contains 0) {
	if ([string](Get-NetFirewallProfile |% {
	if ($_.Enabled -eq 1) {$_.Name}})`
	-Notmatch (((Get-NetFirewallSetting -PolicyStore ActiveStore).ActiveProfile) -Replace ', ','|')) {
		echo ""
		echo "  当前网络下未启用 Windows 防火墙"
		echo ""
		echo "  通常防护软件可与 Windows 防火墙共存，不建议禁用"
		echo ""
		echo "  仍可继续配置，在 Windows 防火墙启用时，过滤规则生效"
		echo ""
		echo "  如不使用过滤规则，仅提交 Peers 列表至 BTN 服务器"
		echo "  请按 Ctrl + C 键退出本脚本后执行以下命令"
		echo ""
		echo "  iex (irm btn-bc.pages.dev/nofw)"
		echo ""
		pause
		Clear-Host
	}
}

$DYKWID = "{da62ac48-4707-4adf-97ea-676470a460f5}"
function Invoke-AddFW {
	echo ""
	echo "  --------------------"
	echo "  添加应用程序过滤规则"
	echo "  --------------------"
	echo ""
	echo "  请指定启用过滤规则的 BT 应用程序文件，可选择快捷方式"
	echo ""
	echo "  过滤规则仅对选中的程序生效，不影响其他程序的通信"
	echo ""
	pause
	Add-Type -AssemblyName System.Windows.Forms
	$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
	$BTINFO.ShowDialog() | Out-Null
	if (!$BTINFO.FileName) {
		echo ""
		echo "  未选择文件"
		echo ""
		echo "  请重新执行脚本，并正确选择 BT 应用程序"
		echo ""
		exit
	}
	$BTPATH = $BTINFO.FileName
	$BTNAME = [System.IO.Path]::GetFileName($BTPATH)
	Remove-NetFirewallRule -DisplayName "BTN_$BTNAME" -ErrorAction Ignore
	New-NetFirewallRule -DisplayName "BTN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	New-NetFirewallRule -DisplayName "BTN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	$PRINCIPAL = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
	$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -AllowStartIfOnBatteries
	$TRIGGER = New-ScheduledTaskTrigger -AtStartup
	$ACTION = New-ScheduledTaskAction -Execute "powershell" -Argument "iex (irm btn-bc.pages.dev)"
	$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION
	Unregister-ScheduledTask BTN_BC_STARTUP -Confirm:$false -ErrorAction Ignore
	Register-ScheduledTask BTN_BC_STARTUP -InputObject $TASK | Out-Null
	echo ""
	echo "  程序路径为：$BTPATH"
	echo ""
	echo "  已配置以下过滤规则"
	echo ""
	Get-NetFirewallRule -DisplayName BTN_* | Select-Object -Property Displayname,Direction | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
	echo ""
}

Invoke-AddFW
return
