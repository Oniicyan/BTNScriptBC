Remove-Variable * -ErrorAction Ignore
$CFGURL = 'https://btn-prod.ghostchu-services.top/ping/config'

if ((Fltmc).Count -eq 3) {
	Write-Output @"
	  
	  请以管理员权限执行
	  
"@
	return
}

$TESTGUID = '{62809d89-9d3b-486b-808f-8c893c1c3378}'
Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID -ErrorAction Ignore
if (New-NetFirewallDynamicKeywordAddress -Id $TESTGUID -Keyword "BT_BAN_TEST" -Address 1.2.3.4 -ErrorAction Ignore) {
	Remove-NetFirewallDynamicKeywordAddress -Id $TESTGUID
} else {
	Write-Output @"
	  
	  当前 Windows 版本不支持动态关键字，请升级操作系统
	  
"@
	return
}

if ((Get-NetFirewallProfile).Enabled -contains 0) {
	if ([string](Get-NetFirewallProfile | %{`
	if ($_.Enabled -eq 1) {$_.Name}})`
	-Notmatch (((Get-NetFirewallSetting -PolicyStore ActiveStore).ActiveProfile) -Replace(', ','|'))) {
		Write-Output @"
		  
		  当前网络下未启用 Windows 防火墙
	  
		  通常防护软件可与 Windows 防火墙共存，不建议禁用
	  
		  仍可继续配置，在 Windows 防火墙启用时，过滤规则生效
	  
"@
		pause
		Clear-Host
	}
}

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2
New-Item -ItemType Directory -Path $env:USERPROFILE\BTN_BC -ErrorAction Ignore | Out-Null

$USERINFO = $env:USERPROFILE\BTN_BC\userinfo.txt
if (Test-Path $USERINFO)) {
	$BCUSER = (-split (Get-Content $USERINFO | Select-String 'BCUSER'))[2]
	$BCPORT = (-split (Get-Content $USERINFO | Select-String 'BCPORT'))[2]
	$BCUSER = (-split (Get-Content $USERINFO | Select-String 'BCUSER'))[2]
	$BCPASS = (-split (Get-Content $USERINFO | Select-String 'BCPASS'))[2]
	$APPUID = (-split (Get-Content $USERINFO | Select-String 'APPUID'))[2]
	$APPSEC = (-split (Get-Content $USERINFO | Select-String 'APPSEC'))[2]
} else {
	Write-Output @"
	  
	  BTNScriptBC 是 BitComet 的外挂脚本，作为 BTN 兼容客户端
	  
	  脚本从 BitComet 的 WebUI 中获取 Peers 列表，并格式化数据提交至 BTN 实例
	
	  提交内容包括活动任务的种子识别符与种子大小
	  
	  种子识别符由种子特征码经过不可逆哈希算法生成，无法复原下载内容
	  
	  更多信息请查阅以下网页
	  
	  https://github.com/Oniicyan/BTNScriptBC
	  https://github.com/PBH-BTN/BTN-Spec
	  
	  同意请继续
	
"@
	pause
	Clear-Host
	Write-Output @"
	  
	  即将开始初始配置，请按照提示进行操作
	  
	  配置 WIndows 防火墙动态关键字
	  
	  请指定启用过滤规则的 BT 应用程序文件，可选择快捷方式
	  
	  过滤规则仅对选中的程序生效，不影响其他程序的通信
		
"@
	pause
	Add-Type -AssemblyName System.Windows.Forms
	$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
	$BTINFO.ShowDialog() | Out-Null
	$BTPATH = $BTINFO.FileName
	Write-Output @"
	  
	  程序路径为："$BTPATH"
	  
"@
	$BCUSER = Read-Host -Prompt '  BitComet WebUI 地址'
	$BCPORT = Read-Host -Prompt '  BitComet WebUI 端口'
	$BCUSER = Read-Host -Prompt '  BitComet WebUI 账号'
	$BCPASS = Read-Host -Prompt '  BitComet WebUI 密码' -AsSecureString | ConvertFrom-SecureString
	$APPUID = Read-Host -Prompt '  BTN AppId'
	$APPSEC = Read-Host -Prompt '  BTN AppSecre'
	Write-Output @"
	BTPATH = $BTPATH
	BCUSER = $BCUSER
	BCPORT = $BCPORT
	BCUSER = $BCUSER
	BCPASS = $BCPASS
	APPUID = $APPUID
	APPSEC = $APPSEC
"@ |
	Out-File $USERINFO
}

pause
