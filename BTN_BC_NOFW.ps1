# BTN 服务器与版本信息在此定义
Remove-Variable * -ErrorAction Ignore
$Host.UI.RawUI.WindowTitle = "BTNScriptBC - nofw"
$Global:ProgressPreference = "SilentlyContinue"
$CONFIGURL = "https://btn-prod.ghostchu-services.top/ping/config"
$USERAGENT = "WindowsPowerShell/$([String]$Host.Version) BTNScriptBC/v0.0.1 BTN-Protocol/7.0.0"

# 检测管理员权限与防火墙状态
# nofw 版初始配置时需要
if ((Fltmc).Count -eq 3) {
	echo ""
	echo "  请以管理员权限执行"
	echo ""
	return
}

# 初始配置
# 关闭 IE 引擎的初始检测，否则可能会导致 Invoke-WebRequest 出错
function Invoke-Setup {
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2
	New-Item -ItemType Directory -Path $ENV:USERPROFILE\BTN_BC -ErrorAction Ignore | Out-Null
	echo ""
	echo "  BTNScriptBC 是 BitComet 的外挂脚本，作为 BTN 兼容客户端"
	echo ""
	echo "  脚本从 BitComet 的 WebUI 中获取 Peers 列表，并格式化数据提交至 BTN 服务器"
	echo ""
	echo "  提交内容包括活动任务的种子识别符与种子大小"
	echo ""
	echo "  种子识别符由种子特征码经过不可逆哈希算法生成，无法复原下载内容"
	echo ""
	echo "  更多信息请查阅以下网页"
	echo ""
	echo "  https://github.com/Oniicyan/BTNScriptBC"
	echo "  https://github.com/PBH-BTN/BTN-Spec"
	echo ""
	echo "  同意请继续"
	echo ""
	pause
	Clear-Host
	$PRINCIPAL = New-ScheduledTaskPrincipal -UserId $env:COMPUTERNAME\$env:USERNAME
	$SETTINGS = New-ScheduledTaskSettingsSet -RestartCount 5 -RestartInterval (New-TimeSpan -Seconds 60) -AllowStartIfOnBatteries
	$TRIGGER = New-ScheduledTaskTrigger -AtStartup
	$ACTION = New-ScheduledTaskAction -Execute "powershell" -Argument "iex (irm btn-bc.pages.dev/nofw)"
	$TASK = New-ScheduledTask -Principal $PRINCIPAL -Settings $SETTINGS -Trigger $TRIGGER -Action $ACTION
	Unregister-ScheduledTask BTN_BC_NOFW_STARTUP -Confirm:$false -ErrorAction Ignore
	Register-ScheduledTask BTN_BC_NOFW_STARTUP -InputObject $TASK | Out-Null
	echo ""
	echo "  已配置以下自启动任务计划"
	echo ""
	echo "  BTN_BC_NOFW_STARTUP"
	echo ""
	echo "  ----------------------------------"
	echo "  请填写用户信息（点击鼠标右键粘贴）"
	echo "  ----------------------------------"
	echo ""
	echo "  地址可填写 IPv4、IPv6 或域名"
	echo "  本机可填写 127.0.0.1，::1 或 localhost"
	echo "  无需 http:// 或 /panel/ 等 URL 标识"
	echo ""
	echo "  WebUI 密码将明文保存至本地文件"
	echo "  不建议重复使用常用密码"
	echo ""
	$UIADDR = Read-Host -Prompt "  BitComet WebUI 地址"
	$UIPORT = Read-Host -Prompt "  BitComet WebUI 端口"
	$UIUSER = Read-Host -Prompt "  BitComet WebUI 账号"
	$UIPASS = Read-Host -Prompt "  BitComet WebUI 密码"
	$APPUID = Read-Host -Prompt "  BTN AppId"
	$APPSEC = Read-Host -Prompt "  BTN AppSecret"
	Write-Output @"
UIADDR = $UIADDR
UIPORT = $UIPORT
UIUSER = $UIUSER
UIPASS = $UIPASS
APPUID = $APPUID
APPSEC = $APPSEC
"@| Out-File $INFOPATH
	echo ""
	echo "  用户信息已保存至 $INFOPATH"
	echo ""
	echo "  可直接编辑用户信息，也或删除以重新配置"
	echo ""
	echo "  执行以下命令清除配置"
	echo ""
	echo "  iex (irm btn-bc.pages.dev/unset)"
	echo ""
	echo "  ------------------------------"
	echo "  初始配置完成，脚本即将开始工作"
	echo "  ------------------------------"
	echo ""
	Write-Host "  脚本开始工作后" -ForegroundColor Green
	Write-Host "  可点击右下角通知区域图标显示／隐藏窗口" -ForegroundColor Green
	echo ""
	Write-Host "  关闭脚本后，可再次执行同样的命令以继续" -ForegroundColor Green
	echo ""
	timeout 120
	Clear-Host
}

# 用户配置与动态关键字信息的初始化
# 仅在检测不到 USERINFO.txt 时，执行初始配置
$INFOPATH = "$ENV:USERPROFILE\BTN_BC\USERINFO.txt"
if (!(Test-Path $INFOPATH)) {
	$SETUP = 1
	Invoke-Setup
}

# 隐藏窗口
$ShowWindowAsyncCode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$ShowWindowAsync = Add-Type -MemberDefinition $ShowWindowAsyncCode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$hwnd = (Get-Process -PID $PID).MainWindowHandle
if ($hwnd -eq [System.IntPtr]::Zero) {
	$TerminalProcess = Get-Process | Where-Object {$_.MainWindowTitle -eq "BTNScriptBC"}
	$hwnd = $TerminalProcess.MainWindowHandle
}
if ($SETUP -ne 1) {$Null = $ShowWindowAsync::ShowWindowAsync($hwnd,0)}

# 通知区域图标
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null
$ICON = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\EaseOfAccessDialog.exe")
$Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
$Main_Tool_Icon.Text = "BTNScriptBC"
$Main_Tool_Icon.Icon = $ICON
$Main_Tool_Icon.Visible = $True

# 通知区域按键
try {
	$CID = [Regex]::Matches(((quser) -Match '^>'),'(?<= )\d+(?= )').Value
} catch {
	$CID = 1
}
$Main_Tool_Icon.Add_Click({
	if ($Global:SWITCH -ne 1) {
		$ShowWindowAsync::ShowWindowAsync($hwnd,$CID)
		$Global:SWITCH = 1
	} else {
		$ShowWindowAsync::ShowWindowAsync($hwnd,0)
		$Global:SWITCH = 0
	}
})

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
	while (!(Test-NetConnection $UIADDR -port $UIPORT -InformationLevel Quiet)) {
		if ((!$FLAG) -or ($FLAG -eq 1)) {Write-Host (Get-Date) [ BitComet WebUI 未开启，每 60 秒检测一次 ] -ForegroundColor Yellow}
		if (!$FLAG) {$FLAG = 2}
		if ($FLAG -eq 1) {$FLAG = 3}
		[System.GC]::Collect()
		Start-Sleep 60
	}
	if ($FLAG -eq 2) {
		if ((Invoke-RestMethod -TimeoutSec 15 -Credential $UIAUTH $UIHOME) -Match 'BitComet') {
			Write-Host (Get-Date) [ BitComet WebUI 访问成功 ] -ForegroundColor Green
		} else {
			Write-Host (Get-Date) [ 目标网页不是 BitComet WebUI，请重新配置 ] -ForegroundColor Red
			Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
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
			Write-Host (Get-Date) [ 网页返回代码 $UIRESP.StatusCode，10 秒后重试 ] -ForegroundColor Yellow
			Start-Sleep 10
		}
	}
}

Test-WebUIPort 2

# 捕获远程服务器的错误响应
function Get-ErrorMessage {
	if (!$Error[0].Exception.Response) {return}
	$streamReader = [System.IO.StreamReader]::new($Error[0].Exception.Response.GetResponseStream())
	try {
		$streamReader.ReadToEnd() | ConvertFrom-Json
	} catch {
		$streamReader.Close()
		return
	}
	$ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
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
	while ($RETRY -lt 3) {
		try {
			$NEWCONFIG = Invoke-RestMethod -TimeoutSec 30 -UserAgent $USERAGENT -Headers $AUTHHEADS $CONFIGURL
			if ($NOWCONFIG.ability.reconfigure.version -ne $NEWCONFIG.ability.reconfigure.version) {
				$NEWCONFIG | ConvertTo-Json | Out-File $ENV:USERPROFILE\BTN_BC\CONFIG.json
				Write-Host (Get-Date) [ 当前 BTN 服务器配置版本为 $NEWCONFIG.ability.reconfigure.version.SubString(0,8) ] -ForegroundColor Green
			}
			break
		} catch {
			Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
			Get-ErrorMessage
			if ($_.Exception.Response.StatusCode.value__ -Match '403|400') {
				Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，请排查后重试 ] -ForegroundColor Red
				Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
				exit
			}
			$RETRY++
			Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，600 秒后第 $RETRY 次重试 ] -ForegroundColor Yellow
			Start-Sleep 600
		}
	}
	if ($RETRY -ge 3) {
		if (Test-Path $ENV:USERPROFILE\BTN_BC\CONFIG.json) {
			$NEWCONFIG = Get-Content $ENV:USERPROFILE\BTN_BC\CONFIG.json | ConvertFrom-Json
			Write-Host (Get-Date) [ 更新 BTN 服务器配置失败，使用上次获取的配置 ] -ForegroundColor Yellow
		} else {
			Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，请确认服务器后重试 ] -ForegroundColor Red
			Write-Host (Get-Date) [ 退出 BTNScriptBC ] -ForegroundColor Red
			exit
		}
	}
	$Global:NEWCONFIG = $NEWCONFIG
}

# 获取给定任务的 Peers 信息并记录到哈希表
function Get-TaskPeers {
	param (
		$SUMMARY,
		$PEERS
	)
	$torrent_identifier = Get-SaltedHash (($SUMMARY.Split([Environment]::NewLine) | Select-String 'InfoHash') -Replace '.*>(?=[0-9a-z])| Piece.*')
	$BIBYTE = (($SUMMARY -Split '>' | Select-String '\d*\.?\d* [KMGTPEZY]?B' | Select-String 'Selected') -Replace 'Selected.*') -Replace ' '
	if ($BIBYTE -Match '\dB') {
		$torrent_size = $BIBYTE -Replace 'B'
	} else {
		$torrent_size = Invoke-Expression $BIBYTE
	}
	$downloader_progress = Get-QuadFloat ([Regex]::Matches(($SUMMARY.Split([Environment]::NewLine) | Select-String 'left \)'),'\d*.?\d%').Value)
	$PEERS -Split '<tr>' | Select-String '>[IciC_]{4}<' |% {
		if ($_ -Match '(\d{1,3}\.){3}\d{1,3}:\d{1,5}') {
			$ip_address = $Matches[0].Split(':')[0]
			$peer_port = $Matches[0].Split(':')[1]
		} elseif ($_ -Match '2[0-9a-f]{3}:([0-9a-f]{1,4}):(:?[0-9a-f]{1,4}:?){1,6}:\d{1,5}') {
			$ip_address = $Matches[0] -Replace ':[0-9]{1,5}$'
			$peer_port = ($Matches[0] -Split ':')[-1]
		} else {
			Write-Host (Get-Date) [ 记录一个无法识别的 Peer 到 UNKNOWN.txt ] -ForegroundColor Yellow
			$_ | Out-File -Append $ENV:USERPROFILE\BTN_BC\UNKNOWN.txt
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
		$RATESTR = $_ -Replace '(Remote|Local).*'
		$RATEVAL = [Regex]::Matches($_,'(?<=>)\d*\.?\d* [KMGTPEZY]?B\/s(?=<)')
		if ($RATEVAL.Count -eq 0) {
			$rt_download_speed = 0
			$rt_upload_speed = 0
		} elseif ($RATEVAL.Count -eq 1) {
			if ([Regex]::Matches($_,'(?<=[0-9a-f]{40}).*') -Cmatch '..i.') {
				$rt_download_speed = Invoke-Expression (($RATEVAL[0].Value -Replace ' ') -Replace '/s')
				$rt_upload_speed = 0
			} else {
				$rt_download_speed = 0
				$rt_upload_speed = Invoke-Expression (($RATEVAL[0].Value -Replace ' ') -Replace '/s')
			}
		} elseif ($RATEVAL.Count -eq 2) {
			$rt_download_speed = Invoke-Expression (($RATEVAL[1].Value -Replace ' ') -Replace '/s')
			$rt_upload_speed = Invoke-Expression (($RATEVAL[0].Value -Replace ' ') -Replace '/s')
		}
		$peer_progress = Get-QuadFloat ([Regex]::Matches($_ ,'\d*.?\d%'))
		$peer_flag = ""
		switch -Regex ([Regex]::Matches($_,'[IciC_]{4}').Value) {
			'Ic..' {$peer_flag = $peer_flag + 'd '}
			'I_..' {$peer_flag = $peer_flag + 'D '}
			'..iC' {$peer_flag = $peer_flag + 'u '}
			'..i_' {$peer_flag = $peer_flag + 'U '}
			'__..' {$peer_flag = $peer_flag + 'K '}
			'..__' {$peer_flag = $peer_flag + '? '}
		}
		if ($_ -Match 'Remote') {$peer_flag = $peer_flag + 'I'}
		$PEERHASH = @{
			ip_address = $ip_address
			peer_port = [Int]$peer_port
			peer_id = $peer_id
			client_name = $client_name
			torrent_identifier = $torrent_identifier
			torrent_size = [Math]::Round($torrent_size)
			downloaded = [Math]::Round($downloaded)
			uploaded = [Math]::Round($uploaded)
			rt_download_speed = [Math]::Round($rt_download_speed)
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
	$ACTIVE = ((Invoke-RestMethod -TimeoutSec 5 -Credential $UIAUTH ${UIHOME}task_list) -Split '<.?tr>' -Replace '> (HTTPS|HTTP|FTP) <.*' -Split "'" | Select-String '.*action=stop') -Split '&|=' | Select-String '.*\d' |% {"${UIHOME}task_detail?id=" + $_}
	Write-Host (Get-Date) [ 分析 $ACTIVE.Count 个活动任务 ] -ForegroundColor Cyan
	$SUBMITHASH = @"
{
	"populate_time": $([DateTimeOffset]::Now.ToUnixTimeMilliseconds()),
	"peers": []
}
"@ | ConvertFrom-Json
	$ACTIVE |% {Get-TaskPeers (Invoke-RestMethod -Credential $UIAUTH $_) (Invoke-RestMethod -Credential $UIAUTH ${_}`&show=peers)}
	$SUBMITHASH | ConvertTo-Json | Out-File $PEERSJSON
	Write-Host (Get-Date) [ 提取 $($SUBMITHASH.peers.Count) 个活动 Peers，耗时 $((([DateTimeOffset]::Now.ToUnixTimeMilliseconds()) - $SUBMITHASH.populate_time) / 1000) 秒 ] -ForegroundColor Cyan
}

# JSON 打包为 Gzip 并提交至 BTN 服务器
$PEERSJSON = "$ENV:USERPROFILE\BTN_BC\PEERS.json"
$PEERSGZIP = "$ENV:USERPROFILE\BTN_BC\PEERS.gzip"
function Invoke-SumbitPeers {
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
		Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
		Get-ErrorMessage
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
	[System.GC]::Collect()
	if (!$NOWCONFIG) {Get-BTNConfig}
	if (
		$NOWCONFIG.ability.submit_peers.interval -ne $NEWCONFIG.ability.submit_peers.interval -or
		$NOWCONFIG.ability.reconfigure.interval -ne $NEWCONFIG.ability.reconfigure.interval
	) {
		$NOWCONFIG = $NEWCONFIG
		$NOWCONFIG.ability.PSObject.Properties.Name |% {
			$DELAY = Get-Random -Maximum $NOWCONFIG.ability.$_.random_initial_delay
			$NOWCONFIG.ability.$_ | Add-Member next ((Get-Date) + (New-TimeSpan -Seconds (($NOWCONFIG.ability.$_.interval + $DELAY) / 1000)))
		}
		$NOWCONFIG.ability.submit_peers | Add-Member cmd "Get-PeersJson; Invoke-SumbitPeers"
		$NOWCONFIG.ability.reconfigure | Add-Member cmd "Get-BTNConfig"
		Write-Host (Get-Date) [ BTNScriptBC 开始循环工作 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.submit_peers.interval / 1000) 秒提交 Peers 快照 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.reconfigure.interval / 1000) 秒查询 BTN 服务器配置更新 ] -ForegroundColor Cyan
	}
	$JOBLIST = $NOWCONFIG.ability.PSObject.Properties.Value | Sort-Object next
	if ($JOBLIST[0].cmd) {
		if ((Get-Date) -lt $JOBLIST[0].next) {Start-Sleep ($JOBLIST[0].next - (Get-Date)).TotalSeconds}
		Invoke-Expression $JOBLIST[0].cmd
		$JOBLIST[0].next = ((Get-Date) + (New-TimeSpan -Seconds ($JOBLIST[0].interval / 1000)))
	} else {
		$JOBLIST[0].next = ((Get-Date) + (New-TimeSpan -Seconds ($JOBLIST[0].interval * 1000)))
	}
}
