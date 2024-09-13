# BTN 服务器与版本信息等在此定义
Remove-Variable * -ErrorAction Ignore
$Host.UI.RawUI.WindowTitle = "BTNScriptBC_$PID"
$Global:ProgressPreference = "SilentlyContinue"
$CONFIGURL = "https://btn-prod.ghostchu-services.top/ping/config"
$SCRIPTURL = "btn-bc.pages.dev/nofw"
$USERAGENT = "WindowsPowerShell/$([String]$Host.Version) BTNScriptBC/v0.0.1 BTN-Protocol/0.0.1"
$APPWTPATH = "$ENV:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"

Write-Host

# 检测 IE 引擎是否可用
# 不可用时提权执行
try {
	Invoke-WebRequest baidu.com | Out-Null
} catch {
	if ($_ -Match 'Internet Explorer') {
		if ((Fltmc).Count -eq 3) {
			if (Test-Path $APPWTPATH) {
				$PROCESS = "$APPWTPATH -ArgumentList `"powershell $($MyInvocation.MyCommand.Definition)`""
			} else {
				$PROCESS = "powershell -ArgumentList `"$($MyInvocation.MyCommand.Definition)`""
			}
			Write-Host "  当前 IE 引擎不可用`n"
			Write-Host "  10 秒后以管理员权限继续执行，以绕过 IE 初始检测`n"
			timeout 10
			Invoke-Expression "Start-Process $PROCESS -Verb RunAs"
			return
		} else {
			Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2
		}
	}
}

# 名称变更，此部分保留一段时间
$OLDPATH = "$ENV:USERPROFILE\BTN_BC"
$NEWPATH = "$ENV:USERPROFILE\BTNScriptBC"
if (Test-Path $NEWPATH) {
	Remove-Item $OLDPATH -Force -ErrorAction Ignore
} else {
	Move-Item $OLDPATH $NEWPATH -Force -ErrorAction Ignore
}
if ($OLDTASK = Get-ScheduledTask BTN_BC_* -ErrorAction Ignore) {
	$NEWTASK = New-ScheduledTask -Principal $OLDTASK.Principal -Settings $OLDTASK.Settings -Trigger $OLDTASK.Triggers -Action $OLDTASK.Actions
	Unregister-ScheduledTask BTN_BC_* -Confirm:$false -ErrorAction Ignore
	Register-ScheduledTask BTNScriptBC_STARTUP -InputObject $NEWTASK | Out-Null
}
Set-ScheduledTask BTNScriptBC_STARTUP -Action (New-ScheduledTaskAction -Execute "$NEWPATH\STARTUP.cmd") -ErrorAction Ignore | Out-Null
if (Test-Path $APPWTPATH) {
	if ((Get-Content $NEWPATH\STARTUP.cmd -ErrorAction Ignore) -Notmatch 'wt\.exe') {
		"@start /min $APPWTPATH powershell iex (irm $SCRIPTURL -TimeoutSec 60)" | Out-File -Encoding ASCII $NEWPATH\STARTUP.cmd
	}
}

# 检测重复运行
# $MUTEX = New-Object System.Threading.Mutex($False,'BTNScriptBC')
# if (!($MUTEX.WaitOne(0,$False))) {
#	Write-Host "  请关闭正在运行的脚本后重试"
#	pause
#	return
# }
Get-Item $ENV:TEMP\BTNScriptBC_* -Exclude *$PID | ForEach-Object {
	Stop-Process ($_.Name -Split '_')[-1] -Force -ErrorAction Ignore
	Remove-Item $_
}
New-Item $ENV:TEMP\BTNScriptBC_$PID -ErrorAction Ignore | Out-Null
try {
	[System.IO.File]::Open("$ENV:TEMP\BTNScriptBC_$PID",[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::None) | Out-Null
} catch {}

# 初始配置
# 关闭 IE 引擎的初始检测，否则可能会导致 Invoke-WebRequest 出错
function Invoke-Setup {
	Write-Host "  BTNScriptBC 是 BitComet 的外挂脚本，作为 BTN 兼容客户端`n"
	Write-Host "  脚本从 BitComet 的 WebUI 中获取 Peers 列表，并格式化数据提交至 BTN 服务器`n"
	Write-Host "  提交内容包括活动任务的种子识别符与种子大小`n"
	Write-Host "  种子识别符由种子特征码经过不可逆哈希算法生成，不会透露用户的下载内容`n"
	Write-Host "  更多信息请查阅以下网页`n"
	Write-Host "  https://github.com/Oniicyan/BTNScriptBC"
	Write-Host "  https://github.com/PBH-BTN/BTN-Spec"
	Write-Host "`n  同意请继续`n"
	pause
	Clear-Host
	Write-Host
	Write-Host "  --------------------"
	Write-Host "  请指定脚本的启动方式"
	Write-Host "  --------------------`n"
	Write-Host "  脚本会在通知区域显示图标，可点击显示／隐藏窗口"
	Write-Host "  BitComet 未启动时，每 60 秒检测一次`n"
	Write-Host "  1. 跟随用户启动"
	Write-Host "     通过任务计划程序，在用户登录时启动脚本`n"
	Write-Host "  2. 桌面快捷方式"
	Write-Host "     在桌面生成快捷方式，由用户按需启动`n"
	Write-Host "  3. 跳过启动配置"
	Write-Host "     不配置启动方式，用户自行操作"
	$STARTUP = Read-Host "`n请输入 1-3（默认为 跟随用户启动）"
	if (Test-Path $APPWTPATH) {
		"@start /min $APPWTPATH powershell iex (irm $SCRIPTURL -TimeoutSec 60)" | Out-File -Encoding ASCII $USERPATH\STARTUP.cmd
	} else {
		"@start /min powershell iex (irm $SCRIPTURL -TimeoutSec 60)" | Out-File -Encoding ASCII $USERPATH\STARTUP.cmd
	}
	$LINKPATH = "$USERPATH\BTNScriptBC.lnk"
	$WshShell = New-Object -COMObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($LINKPATH)
	$Shortcut.TargetPath = "$USERPATH\STARTUP.cmd"
	$Shortcut.IconLocation = "$ENV:WINDIR\System32\EaseOfAccessDialog.exe"
	$Shortcut.Save()
	$LINKBYTE = [System.IO.File]::ReadAllBytes($LINKPATH)
	$LINKBYTE[0x15] = $LINKBYTE[0x15] -bor 0x20
	[System.IO.File]::WriteAllBytes($LINKPATH,$LINKBYTE)
	Unregister-ScheduledTask BTNScriptBC_STARTUP -Confirm:$false -ErrorAction Ignore
	switch ($STARTUP) {
		2 {
			Copy-Item $LINKPATH $([Environment]::GetFolderPath("Desktop"))
			Write-Host "`n  已配置桌面快捷方式：BTNScriptBC.lnk`n"
		}
		3 {}
		default {
			$PRINCIPAL = New-ScheduledTaskPrincipal -UserId $ENV:COMPUTERNAME\$ENV:USERNAME
			$SETTINGS = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -AllowStartIfOnBatteries
			$TRIGGER = New-ScheduledTaskTrigger -AtLogon -User $ENV:COMPUTERNAME\$ENV:USERNAME
			$ACTION = New-ScheduledTaskAction -Execute "$USERPATH\STARTUP.cmd"
			$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION
			Register-ScheduledTask BTNScriptBC_STARTUP -InputObject $TASK -ErrorAction Ignore | Out-Null
			Write-Host "`n  已配置自启动任务计划：BTNScriptBC_STARTUP`n"
		}
	}
	Write-Host "  ----------------------------------"
	Write-Host "  请填写用户信息（点击鼠标右键粘贴）"
	Write-Host "  ----------------------------------`n"
	Write-Host "  需要填写的项目为如下`n"
	Write-Host "    BitComet WebUI 地址"
	Write-Host "    BitComet WebUI 端口"
	Write-Host "    BitComet WebUI 账号"
	Write-Host "    BitComet WebUI 密码"
	Write-Host "    BTN AppId"
	Write-Host "    BTN AppSecret`n"
	Write-Host "  WebUI 地址可直接粘贴 URL"
	Write-Host "  也可填写 IPv4、IPv6 或域名，可加端口`n"
	Write-Host "  WebUI 密码将明文保存至本地文件"
	Write-Host "  不建议重复使用常用密码"
	$UIADDR = Read-Host -Prompt "`n  BitComet WebUI 地址"
	if ($UIADDR -Match ':') {
		if ($UIADDR -Match '([a-z0-9]*\..*:\d{1,5})|(\w{5,}:\d{1,5})') {
			$UIADDR = $Matches[0].Split(':')[0]
			$UIPORT = $Matches[0].Split(':')[1]
		} elseif ($UIADDR -Match '\[.*]:\d{1,5}') {
			$UIADDR = ($Matches[0] -Split ']:')[0] -Replace '\['
			$UIPORT = ($Matches[0] -Split ']:')[1]
		}
	}
	if (!$UIPORT) {$UIPORT = Read-Host -Prompt "`n  BitComet WebUI 端口"}
	$UIUSER = Read-Host -Prompt "`n  BitComet WebUI 账号"
	$UIPASS = Read-Host -Prompt "`n  BitComet WebUI 密码"
	$APPUID = Read-Host -Prompt "`n  BTN AppId"
	$APPSEC = Read-Host -Prompt "`n  BTN AppSecret"
	Write-Output @"
UIADDR = $UIADDR
UIPORT = $UIPORT
UIUSER = $UIUSER
UIPASS = $UIPASS
APPUID = $APPUID
APPSEC = $APPSEC
"@| Out-File $INFOPATH
	Write-Host 
	Write-Host "  --------------------------------------`n"
	Write-Host "  用户信息已保存至 $INFOPATH`n"
	Write-Host "  可直接编辑用户信息，也可删除以重新配置`n"
	Write-Host "  --------------------------------------`n"
	Write-Host "  初始配置完成，脚本即将开始工作`n"
	Write-Host "  脚本开始工作后" -ForegroundColor Green
	Write-Host "  可点击右下角通知区域图标显示／隐藏窗口`n" -ForegroundColor Green
	Write-Host "  执行以下命令清除所有配置" -ForegroundColor Cyan
	Write-Host "  iex (irm btn-bc.pages.dev/unset)`n"
	Write-Host "  执行以下命令重建桌面快捷方式" -ForegroundColor Cyan
	Write-Host "  iex (irm btn-bc.pages.dev/link)`n"
	Write-Host "  执行以下命令重建自启动任务计划" -ForegroundColor Cyan
	Write-Host "  iex (irm btn-bc.pages.dev/task)"
	timeout 120
	Clear-Host
}

# 加载 user32.dll
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Tricks {
	[DllImport("user32.dll")]
	public static extern IntPtr FindWindow(string lpClassName,string lpWindowName);
	public static IntPtr FindWindowByName(string lpWindowName) {
		return FindWindow(null, lpWindowName);
	}
	[DllImport("user32.dll")]
	public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
	[DllImport("user32.dll")]
	[return: MarshalAs(UnmanagedType.Bool)]
	public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@
$hwnd = [Tricks]::FindWindowByName($Host.UI.RawUI.WindowTitle)

# 用户配置与动态关键字信息的初始化
# 仅在检测不到 USERINFO.txt 时，执行初始配置
# 初始配置时显示窗口，否则隐藏
$USERPATH = "$ENV:USERPROFILE\BTNScriptBC"
$INFOPATH = "$USERPATH\USERINFO.txt"
New-Item -ItemType Directory -Path $USERPATH -ErrorAction Ignore | Out-Null
if (!(Test-Path $INFOPATH)) {
	$SETUP = 1
	[Tricks]::SetForegroundWindow($hwnd) | Out-Null
	[Tricks]::ShowWindowAsync($hwnd,1) | Out-Null
	Invoke-Setup
}
if ($SETUP) {
	$WINDOW = 1
} else {
	[Tricks]::ShowWindowAsync($hwnd,0) | Out-Null
	$WINDOW = 0
}

# 通知区域图标
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null
$ICON = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\EaseOfAccessDialog.exe")
$Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
$Main_Tool_Icon.Text = "BTNScriptBC - nofw"
$Main_Tool_Icon.Icon = $ICON
$Main_Tool_Icon.Visible = $True

# 通知区域按键
$Main_Tool_Icon.Add_Click({
	switch ($_.Button) {
		([Windows.Forms.MouseButtons]::Left) {
			switch ($WINDOW) {
				0 {
					[Tricks]::SetForegroundWindow($hwnd)
					[Tricks]::ShowWindowAsync($hwnd,1)
					$Global:WINDOW = 1
				}
				1 {
					[Tricks]::ShowWindowAsync($hwnd,0)
					$Global:WINDOW = 0
				}
			}
		}
		([Windows.Forms.MouseButtons]::Right) {[System.Windows.Forms.SendKeys]::SendWait('^')}
	}
})

# 通知区域菜单
$Menu_Peer = New-Object System.Windows.Forms.MenuItem
$Menu_Peer.Enabled = $False
$Menu_Peer.Text = "强制提交快照"
$Menu_Conf= New-Object System.Windows.Forms.MenuItem
$Menu_Conf.Enabled = $False
$Menu_Conf.Text = "强制更新配置"
$Menu_Show = New-Object System.Windows.Forms.MenuItem
$Menu_Show.Enabled = $False
$Menu_Show.Text = "显示任务安排"
$Contextmenu = New-Object System.Windows.Forms.ContextMenu
$Main_Tool_Icon.ContextMenu = $Contextmenu
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Peer)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Conf)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Show)
$Menu_Peer.add_Click({
	$Global:JOBFLAG = 1
	$NOWCONFIG.ability.submit_peers.next = 0
	Get-Job | Stop-Job
})
$Menu_Conf.add_Click({
	$Global:JOBFLAG = 2
	Get-Job | Stop-Job
})
$Menu_Show.add_Click({
	Write-Host (Get-Date) [ 下次提交快照在 $($NOWCONFIG.ability.submit_peers.next) ] -ForegroundColor Cyan
	Write-Host (Get-Date) [ 下次查询配置在 $($NOWCONFIG.ability.reconfigure.next) ] -ForegroundColor Cyan
})

Clear-Host
[System.GC]::Collect()

# 启动信息
Write-Host (Get-Date) [ $USERAGENT ] -ForegroundColor Cyan
$CONFIGURL -Match '(\w+:\/\/)([^\/:]+)(:\d*)?([^# ]*)' | Out-Null
Write-Host (Get-Date) [ BTN 服务器：$($Matches[1] + $Matches[2]) ] -ForegroundColor Cyan
Write-Host (Get-Date) [ 点击通知区域图标以显示／隐藏窗口 ] -ForegroundColor Cyan

# 载入用户信息并定义基本变量
$USERINFO = ConvertFrom-StringData (Get-Content -Raw $INFOPATH)
if ($USERINFO.Count -eq 6) {
	Write-Host (Get-Date) [ 用户信息载入成功 ] -ForegroundColor Green
} else {
	Write-Host (Get-Date) [ 用户信息已载入，但条目数量不符 ] -ForegroundColor Yellow
	Write-Host (Get-Date) [ 如在运行中发生错误，请删除 USERINFO.txt 后重试 ] -ForegroundColor Yellow
}
$UIADDR = $USERINFO['UIADDR']
$UIPORT = $USERINFO['UIPORT']
$UIUSER = $USERINFO['UIUSER']
$UIPASS = ConvertTo-SecureString ($USERINFO['UIPASS']) -AsPlainText -Force
$APPUID = $USERINFO['APPUID']
$APPSEC = $USERINFO['APPSEC']
if ($UIADDR -Match ':') {
	$UIHOST = "[${UIADDR}]:${UIPORT}"
} else {
	$UIHOST = "${UIADDR}:${UIPORT}"
}
$AUTHHEADS = @{"Authorization"="Bearer $APPUID@$APPSEC"; "X-BTN-AppID"="$APPUID"; "X-BTN-AppSecret"="$APPSEC"}
Write-Host (Get-Date) [ BitComet WebUI 目标主机为 $UIHOST ] -ForegroundColor Cyan

# BC WebUI 的生存检测
# 第一次检测传递参数 1，仅检测端口连通性，在失败时显示一次消息
# 第二次检测传递参数 2，测试网页是否 BC WebUI，成功与否都显示消息
# 循环工作时，不提供参数，在端口检测失败时显示一次消息，并在端口连通后测试网页
function Test-WebUIPort {
	param($FLAG)
	while (!(Test-NetConnection $UIADDR -port $UIPORT -InformationLevel Quiet -WarningAction SilentlyContinue)) {
		if ((!$FLAG) -or ($FLAG -eq 1)) {Write-Host (Get-Date) [ BitComet WebUI 未开启，每 60 秒检测一次 ] -ForegroundColor Yellow}
		if (!$FLAG) {$FLAG = 2}
		if ($FLAG -eq 1) {$FLAG = 3}
		[System.GC]::Collect()
		Start-Job {Start-Sleep 60} | Out-Null
		Get-Job | Wait-Job | Out-Null
		Get-Job | Remove-Job -Force
		if ($JOBFLAG) {
			Write-Host (Get-Date) [ 结束正在等待的操作，强制执行任务 ] -ForegroundColor Yellow
			return
		}
	}
	if ($FLAG -eq 2) {
		if ($BCRESP = (Invoke-RestMethod -TimeoutSec 15 -Credential $UIAUTH $UIHOME) -Split '<br>' | Select-String 'BitComet') {
			Write-Host (Get-Date) [ BitComet WebUI 访问成功 ] -ForegroundColor Green
			Write-Host (Get-Date) [ $([Regex]::Matches($BCRESP[-1],'\w.*\w').Value) ] -ForegroundColor Cyan
		} else {
			Write-Host (Get-Date) [ 目标网页不是 BitComet WebUI，请重新配置 ] -ForegroundColor Red
			Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
			pause
			$Main_Tool_Icon.Dispose()
			exit
		}
	}
}

Test-WebUIPort 1

# 允许不安全的证书，考虑 BC WebUI 可能开启强制 HTTPS
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# 获取主页 URL，需要捕获 301 / 302 重定向信息
$UIHOME = "http://$UIHOST"
$UIAUTH = New-Object System.Management.Automation.PSCredential($UIUSER,($UIPASS))
while ($UIRESP.StatusCode -ne 200) {
	try {
		$UIRESP = Invoke-Webrequest -TimeoutSec 15 -Credential $UIAUTH $UIHOME -MaximumRedirection 0 -ErrorAction Ignore
	} catch {
		Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
		if ($_ -Match '401') {
			Write-Host (Get-Date) [ 目标网页认证失败，请确认 WebUI 的账号与密码 ] -ForegroundColor Red
		} else {
			Write-Host (Get-Date) [ 目标网页访问失败，请排查后重试 ] -ForegroundColor Red
		}
		Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
		pause
		$Main_Tool_Icon.Dispose()
		return
	}
	switch ($UIRESP.StatusCode) {
		200 {break}
		301 {$UIHOME = (-Split ($UIRESP.RawContent.Split([Environment]::NewLine) | Select-String 'Location:.*'))[1]}
		302 {
			$UIPATH = (-Split ($UIRESP.RawContent.Split([Environment]::NewLine) | Select-String 'Location:.*'))[1]
			$UIHOME = [String]($UIHOME | Select-String '.*:\d*') + $UIPATH
		}
		default {
			$RETRY++
			if ($RETRY -le 10) {
				Write-Host (Get-Date) [ 网页返回代码 $UIRESP.StatusCode，10 秒后第 $RETRY 次重试 ] -ForegroundColor Yellow
				Start-Job {Start-Sleep 10} | Out-Null
				Get-Job | Wait-Job | Out-Null
				Get-Job | Remove-Job -Force
				if ($JOBFLAG) {Write-Host (Get-Date) [ 无法跳过本操作，完成后执行 ] -ForegroundColor Yellow}
			} else {
				Write-Host (Get-Date) [ 目标网页访问失败，请排查后重试 ] -ForegroundColor Red
				Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
				pause
				$Main_Tool_Icon.Dispose()
				return
			}
		}
	}
}

Test-WebUIPort 2

# 捕获远程服务器的错误响应
function Get-ErrorMessage {
	if (!$Error[0].Exception.Response) {return}
	$streamReader = [System.IO.StreamReader]::new($Error[0].Exception.Response.GetResponseStream())
	try {
		$ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
	} catch {
		$streamReader.Close()
		return
	}
	$streamReader.Close()
	if ($ErrResp.message) {Write-Host (Get-Date) [ $ErrResp.message ] -ForegroundColor Red}
}

# 百分数转小数，精确到小数点后 4 位
function Get-QuadFloat {
	param ($PERCENT)
	if ($PERCENT -Match '100%') {
		$QUADFLOAT = "1"
	} else {
	$QUADFLOAT = ('0.' + ($PERCENT -Replace '%|\.') + '00').Substring(0,6)
	}
	Write-Output $QUADFLOAT
}

# 从种子特征码计算种子标识符
$CRC32 = add-type @"
[DllImport("ntdll.dll")]
public static extern uint RtlComputeCrc32(uint dwInitial, byte[] pData, int iLen);
"@ -Name CRC32 -PassThru
function Get-SaltedHash {
	param ($INFOHASH)
	$BYTE = [System.Text.Encoding]::UTF8.GetBytes($INFOHASH.ToLower())
	$SALT = ($CRC32::RtlComputeCrc32(0,$BYTE,$BYTE.Count)).ToString("x8")
	$SALT = $SALT.Substring(6,2) + $SALT.Substring(4,2) + $SALT.Substring(2,2) + $SALT.Substring(0,2)
	([System.BitConverter]::ToString(([System.Security.Cryptography.HashAlgorithm]::Create('SHA256')).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($INFOHASH + $SALT))) -Replace '-').ToLower()
}

# 获取 BTN 服务器配置
function Get-BTNConfig {
#	if (!$NOWCONFIG) {$CONFIGURL = $CONFIGURL + "?rand=$(Get-Random)"}
	while ($True) {
		try {
			$NEWCONFIG = Invoke-RestMethod -TimeoutSec 30 -UserAgent $USERAGENT -Headers $AUTHHEADS $CONFIGURL
			if ($NOWCONFIG.ability.reconfigure.version -ne $NEWCONFIG.ability.reconfigure.version) {
				$NEWCONFIG | ConvertTo-Json | Out-File $USERPATH\CONFIG.json
				Write-Host (Get-Date) [ 当前 BTN 服务器配置版本为 $NEWCONFIG.ability.reconfigure.version.SubString(0,8) ] -ForegroundColor Green
			}
			break
		} catch {
			Get-ErrorMessage
			Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
			if ($_.Exception.Response.StatusCode.value__ -Match '403|400') {
				Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，请排查后重试 ] -ForegroundColor Red
				Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
				pause
				$Main_Tool_Icon.Dispose()
				exit
			}
			$RETRY++
			if ($RETRY -gt 3) {
				if (Test-Path $USERPATH\CONFIG.json) {
					$NEWCONFIG = Get-Content $USERPATH\CONFIG.json | ConvertFrom-Json
					Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，使用上次获取的配置 ] -ForegroundColor Yellow
					break
				} else {
					Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，请确认服务器后重试 ] -ForegroundColor Red
					Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
					pause
					$Main_Tool_Icon.Dispose()
					exit
				}
			}
			Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，600 秒后第 $RETRY 次重试 ] -ForegroundColor Yellow
			Start-Job {Start-Sleep 600} | Out-Null
			Get-Job | Wait-Job | Out-Null
			Get-Job | Remove-Job -Force
			if ($JOBFLAG) {
				Write-Host (Get-Date) [ 结束正在等待的操作，强制执行任务 ] -ForegroundColor Yellow
				return
			}
		}
	}
	$Global:NEWCONFIG = $NEWCONFIG
}

# 获取给定任务的 Peers 信息并记录到哈希表
function Get-TaskPeers {
	param ($TASKURL)
	try {
		$SUMMARY = Invoke-RestMethod -TimeoutSec 5 -Credential $UIAUTH $TASKURL
		$PEERS = Invoke-RestMethod -TimeoutSec 5 -Credential $UIAUTH ${TASKURL}`&show=peers
	} catch {
		Write-Host (Get-Date) [ 获取任务详情超时，跳过一个任务 ] -ForegroundColor Yellow
		return
	}
	try {
		$torrent_identifier = Get-SaltedHash (($SUMMARY.Split([Environment]::NewLine) | Select-String 'InfoHash') -Replace '.*>(?=[0-9a-z])| Piece.*')
	} catch {
		Write-Host (Get-Date) [ 获取任务详情失败，跳过一个任务 ] -ForegroundColor Yellow
		return
	}
	if ($torrent_identifier -Match '1ca334e65d854658cf4398db9f2e1c350a1d80b4aa29b2a87b47a1534bb961d2') {
		Write-Host (Get-Date) [ 跳过一个 BTv2 任务 ] -ForegroundColor Yellow
		return
	}
	$BIBYTE = (($SUMMARY -Split '>' | Select-String '\d*\.?\d* [KMGTPEZY]?B' | Select-String 'Selected') -Replace 'Selected.*') -Replace ' '
	if ($BIBYTE -Match '\dB') {
		$torrent_size = $BIBYTE -Replace 'B'
	} else {
		$torrent_size = Invoke-Expression $BIBYTE
	}
	$downloader_progress = Get-QuadFloat ([Regex]::Matches(($SUMMARY.Split([Environment]::NewLine) | Select-String 'left \)'),'\d*.?\d%').Value)
	$PEERS -Split '<tr>' | Select-String '>[IciC_]{4}<' | ForEach-Object {
		if ($_ -Match '(\d{1,3}\.){3}\d{1,3}:\d{1,5}') {
			$ip_address = $Matches[0].Split(':')[0]
			$peer_port = $Matches[0].Split(':')[1]
		} elseif ($_ -Match '2[0-9a-f]{3}:([0-9a-f]{1,4}):(:?[0-9a-f]{1,4}:?){1,6}:\d{1,5}') {
			$ip_address = $Matches[0] -Replace ':[0-9]{1,5}$'
			$peer_port = ($Matches[0] -Split ':')[-1]
		} else {
			Write-Host (Get-Date) [ 记录一个无法识别的 Peer 到 UNKNOWN.txt ] -ForegroundColor Yellow
			$_ | Out-File -Append $USERPATH\UNKNOWN.txt
			return
		}
		switch -Regex ($ip_address) {
			'^10\.' {return}
			'^172\.(1[6-9]|2[0-9]|3[01])\.' {return}
			'^192\.168\.' {return}
			'^100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.' {return}
			'^127\.' {return}
		}
		if ($ip_address -Match '^f[cde]..:') {return}
		if ($_ -Match '[0-9a-f]{40}') {
			$peer_id = -Join ($Matches[0].SubString(0,16) -Replace '(..)','[char]0x${0};'| Invoke-Expression)
		} else {
			$peer_id = ""
		}
		$_ -Match '(?<=\d:\d\d:\d\d<\/td><td>).*?(?=<)' | Out-Null
		if ($Matches[0] -Match 'n/a') {
			$client_name = ""
		} else {
			$client_name = $Matches[0]
		}
		$_ -Match '(?<=>)\d*\.?\d* [KMGTPEZY]?B(?=<)' | Out-Null
		$downloaded = Invoke-Expression ((([Regex]::Matches($_,'(?<=>)\d*\.?\d* [KMGTPEZY]?B(?=<)')).Value[0]) -Replace ' ')
		$uploaded = Invoke-Expression ((([Regex]::Matches($_,'(?<=>)\d*\.?\d* [KMGTPEZY]?B(?=<)')).Value[1]) -Replace ' ')
		$peer_progress = Get-QuadFloat ([Regex]::Matches($_ ,'\d*.?\d%'))
		$BCFLAGS = [Regex]::Matches($_,'(?<=>)[IciC_]{4}(?=<)').Value
		$peer_flag = ""
		switch -Regex ($BCFLAGS) {
			'Ic..' {$peer_flag = $peer_flag + 'd '}
			'I_..' {$peer_flag = $peer_flag + 'D '}
			'__..' {$peer_flag = $peer_flag + 'K '}
		}
		switch -Regex ($BCFLAGS) {
			'..iC' {$peer_flag = $peer_flag + 'u '}
			'..i_' {$peer_flag = $peer_flag + 'U '}
			'..__' {$peer_flag = $peer_flag + '? '}
		}
		if ($_ -Match 'Remote') {
			$peer_flag = $peer_flag + 'I'
		} else {
			$peer_flag = $peer_flag -Replace ' $'
		}
		$RATESTR = $_ -Replace '(Remote|Local).*'
		$RATEVAL = [Regex]::Matches($RATESTR,'(?<=>)\d*\.?\d* [KMGTPEZY]?B\/s(?=<)')
		switch ($RATEVAL.Count) {
			0 {
				$rt_download_speed = 0
				$rt_upload_speed = 0
			}
			1 {
				if ($downloader_progress -eq 1 -or $peer_flag -Cnotmatch 'u') {
					$rt_download_speed = 0
					$rt_upload_speed = Invoke-Expression (($RATEVAL[0].Value -Replace ' ') -Replace '/s')
				} else {
					$rt_download_speed = Invoke-Expression (($RATEVAL[0].Value -Replace ' ') -Replace '/s')
					$rt_upload_speed = 0
				}
			}
			2 {
				$rt_download_speed = Invoke-Expression (($RATEVAL[0].Value -Replace ' ') -Replace '/s')
				$rt_upload_speed = Invoke-Expression (($RATEVAL[1].Value -Replace ' ') -Replace '/s')
			}
		}
		$PEERHASH = @{
			ip_address = $ip_address
			peer_port = [Int]$peer_port
			peer_id = $peer_id
			client_name = $client_name
			torrent_identifier = $torrent_identifier
			torrent_size = [Math]::Round($torrent_size)
			downloaded = [Math]::Round($downloaded)
			rt_download_speed = [Math]::Round($rt_download_speed)
			uploaded = [Math]::Round($uploaded)
			rt_upload_speed = [Math]::Round($rt_upload_speed)
			peer_progress = [decimal]$peer_progress
			downloader_progress = [decimal]$downloader_progress
			peer_flag = $peer_flag -Replace ' $'
		}
		$SUBMITHASH.peers += $PEERHASH
	}
}

# 获取活动任务列表，并调用上述函数传递 URL 参数获取 Peers 哈希表
# Peers 哈希表转换为 JSON 保存
function Get-PeersJson {
	Test-WebUIPort
	try {
		$ACTIVE = ((Invoke-RestMethod -TimeoutSec 15 -Credential $UIAUTH ${UIHOME}task_list) -Split '<.?tr>' -Replace '> (HTTPS|HTTP|FTP) <.*' -Split "'" | Select-String '.*action=stop') -Split '&|=' | Select-String '.*\d' | ForEach-Object {"${UIHOME}task_detail?id=" + $_}
	} catch {
		Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
		Write-Host (Get-Date) [ 获取任务列表超时，跳过本次提交 ] -ForegroundColor Yellow
		$Global:SUBMIT = 0
		return
	}
	Write-Host (Get-Date) [ 分析 $ACTIVE.Count 个活动任务 ] -ForegroundColor Cyan
	$SUBMITHASH = @"
{
	"populate_time": $([DateTimeOffset]::Now.ToUnixTimeMilliseconds()),
	"peers": []
}
"@ | ConvertFrom-Json
	$ACTIVE | ForEach-Object {Get-TaskPeers $_}
	Write-Host (Get-Date) [ 提取 $($SUBMITHASH.peers.Count) 个活动 Peers，耗时 $((([DateTimeOffset]::Now.ToUnixTimeMilliseconds()) - $SUBMITHASH.populate_time) / 1000) 秒 ] -ForegroundColor Cyan
	if ($SUBMITHASH.peers.Count -eq 0) {
		$Global:SUBMIT = 0
		return
	}
	$SUBMITHASH | ConvertTo-Json | Out-File $PEERSJSON
	$Global:SUBMIT = 1
}

# JSON 打包为 Gzip 并提交至 BTN 服务器
$PEERSJSON = "$USERPATH\PEERS.json"
$PEERSGZIP = "$USERPATH\PEERS.gzip"
function Invoke-SumbitPeers {
	if ($SUBMIT -eq 0) {
		Write-Host (Get-Date) [ 没有需要提交的数据 ] -ForegroundColor Green
		return
	}
	$JSONSTREAM = New-Object System.IO.FileStream($PEERSJSON,([IO.FileMode]::Open),([IO.FileAccess]::Read),([IO.FileShare]::Read))
	$GZIPSTREAM = New-Object System.IO.FileStream($PEERSGZIP,([IO.FileMode]::Create),([IO.FileAccess]::Write),([IO.FileShare]::None))
	$GZIPBUFFER = New-Object System.IO.Compression.GZipStream($GZIPSTREAM,[System.IO.Compression.CompressionMode]::Compress)
	$JSONSTREAM.CopyTo($GZIPBUFFER)
	$GZIPBUFFER.Dispose()
	$JSONSTREAM.Dispose()
	$GZIPSTREAM.Dispose()
	$GZIPLENGTH = [Regex]::Matches(((Get-Item $PEERSGZIP).Length / 1KB),'\d*\.?\d')[0].Value
	if ($GZIPLENGTH -Notmatch '\.\d') {$GZIPLENGTH = $GZIPLENGTH + '.0'}
	try {
		Invoke-RestMethod -TimeoutSec 30 -UserAgent $USERAGENT -Headers ($AUTHHEADS + @{"Content-Encoding"="gzip"; "Content-Type"="application/json"}) -Method Post -InFile $PEERSGZIP $NOWCONFIG.ability.submit_peers.endpoint | Out-Null
		Write-Host (Get-Date) [ 提交 Peers 快照成功，数据大小 $GZIPLENGTH KiB ] -ForegroundColor Green
	} catch {
		Get-ErrorMessage
		Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
		Write-Host (Get-Date) [ 提交 Peers 快照失败，数据大小 $GZIPLENGTH KiB ] -ForegroundColor Yellow
	}
	Remove-Item $PEERSGZIP
}

# 首次启动时，先获取 BTN 服务器配置，并添加下次执行时间
# 遵守 BTN 规范的首次随机延迟要求
# 以下循环工作流程
# 1. 按照下次执行时间排列任务
# 2. 等待并执行最近的一个（排列首位的）任务
# 3. 执行完成后，安排下次时间，回到 1.
# 当 BTN 服务器配置的间隔要求发生变化时，重新配置下次执行时间
while ($True) {
	Get-Job | Remove-Job -Force
	$Global:JOBFLAG = 0
	if (!$NOWCONFIG) {
		Get-BTNConfig
		$Menu_Peer.Enabled = $True
		$Menu_Conf.Enabled = $True
		$Menu_Show.Enabled = $True
	}
	if (
		$NOWCONFIG.ability.submit_peers.interval -ne $NEWCONFIG.ability.submit_peers.interval -or
		$NOWCONFIG.ability.reconfigure.interval -ne $NEWCONFIG.ability.reconfigure.interval
	) {
		$NOWCONFIG = $NEWCONFIG
		$NOWCONFIG.ability.PSObject.Properties.Name | ForEach-Object {
			$DELAY = Get-Random -Maximum $NOWCONFIG.ability.$_.random_initial_delay
			$NOWCONFIG.ability.$_ | Add-Member next ((Get-Date) + (New-TimeSpan -Seconds (($NOWCONFIG.ability.$_.interval + $DELAY) / 1000)))
		}
		$NOWCONFIG.ability.submit_peers | Add-Member cmd "Get-PeersJson; Invoke-SumbitPeers"
		$NOWCONFIG.ability.reconfigure | Add-Member cmd "Get-BTNConfig"
		Write-Host (Get-Date) [ BTNScriptBC 开始循环工作 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.submit_peers.interval / 1000) 秒提交 Peers 快照 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.reconfigure.interval / 1000) 秒查询 BTN 服务器配置更新 ] -ForegroundColor Cyan
	}
	[System.GC]::Collect()
	$JOBLIST = $NOWCONFIG.ability.PSObject.Properties.Value | Sort-Object next
	if (!$JOBLIST[0].cmd) {$JOBLIST[0].next = ((Get-Date) + (New-TimeSpan -Seconds ($JOBLIST[0].interval * 1000))); continue}
	if ((Get-Date) -lt $JOBLIST[0].next) {
		Start-Job {Start-Sleep ($Using:JOBLIST[0].next - (Get-Date)).TotalSeconds} | Out-Null
		Get-Job | Wait-Job | Out-Null
	}
	switch ($JOBFLAG) {
		0 {Invoke-Expression $JOBLIST[0].cmd; $JOBLIST[0].next = ((Get-Date) + (New-TimeSpan -Seconds ($JOBLIST[0].interval / 1000)))}
		1 {continue}
		2 {Remove-Variable NOWCONFIG}
	}
}
