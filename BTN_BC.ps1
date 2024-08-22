Remove-Variable * -ErrorAction Ignore
$Global:ProgressPreference = "SilentlyContinue"
$CONFIGURL = "https://btn-prod.ghostchu-services.top/ping/config"
$USERAGENT = "WindowsPowerShell/$([String]$Host.Version) BTNScriptBC/v0.0.0-dev BTN-Protocol/0.0.0-dev"
$AUTHHEADS = @{"Authorization"="Bearer $APPUID@$APPSEC"; "X-BTN-AppID"="$APPUID"; "X-BTN-AppSecret"="$APPSEC"}

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

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2
New-Item -ItemType Directory -Path $ENV:USERPROFILE\BTN_BC -ErrorAction Ignore | Out-Null
$INFOPATH = "$ENV:USERPROFILE\BTN_BC\USERINFO.txt"
$DYKWID = "{da62ac48-4707-4adf-97ea-676470a460f5}"

if (!(Test-Path $INFOPATH)) {
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
	echo ""
	echo "  ------------------------------------"
	echo "  即将开始初始配置，请按照提示进行操作"
	echo "  ------------------------------------"
	echo ""
	echo "  配置 WIndows 防火墙过滤规则与动态关键字"
	echo ""
	echo "  请指定启用过滤规则的 BT 应用程序文件，可选择快捷方式"
	echo ""
	echo "  过滤规则仅对选中的程序生效，不影响其他程序的通信"
	echo ""
	echo "  如需为多个程序启用过滤规则，请在完成配置后执行以下命令"
	echo ""
	echo "  iex (irm btn-bc.pages.dev/add)"
	echo ""
	echo "  如不使用过滤规则，仅提交 Peers 列表至 BTN 服务器"
	echo "  请按 Ctrl + C 键退出本脚本后执行以下命令"
	echo ""
	echo "  iex (irm btn-bc.pages.dev/nofw)"
	echo ""
	pause
	Add-Type -AssemblyName System.Windows.Forms
	$BTINFO = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
	$BTINFO.ShowDialog() | Out-Null
	$BTPATH = $BTINFO.FileName
	$BTNAME = [System.IO.Path]::GetFileName($BTPATH)
	Remove-NetFirewallRule -DisplayName "BTN_$BTNAME" -ErrorAction Ignore
	New-NetFirewallRule -DisplayName "BTN_$BTNAME" -Direction Inbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	New-NetFirewallRule -DisplayName "BTN_$BTNAME" -Direction Outbound -Action Block -Program $BTPATH -RemoteDynamicKeywordAddresses $DYKWID | Out-Null
	echo ""
	echo "  程序路径为：$BTPATH"
	echo ""
	echo "  已配置以下过滤规则"
	echo ""
	Get-NetFirewallRule -DisplayName BTN_* | Select-Object -Property Displayname, Direction | ForEach-Object {'  ' + $_.DisplayName + ' (' + $_.Direction + ')'}
	echo ""
	echo "  已配置以下动态关键字"
	echo ""
	echo "  BTN_IPLIST"
	echo ""
	echo "  ----------------------------------"
	echo "  请填写用户信息（点击鼠标右键粘贴）"
	echo "  ----------------------------------"
	echo ""
	echo "  地址可填写 IPv4、IPv6 或域名"
	echo "  无需 http:// 或 /panel/ 等 URL 标识"
	echo "  本机可填写 127.0.0.1 或 localhost"
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
	echo "  如有需要，可编辑或删除用户信息"
	echo ""
	echo "  ------------------------------"
	echo "  初始配置完成，脚本即将开始工作"
	echo "  ------------------------------"
	echo ""
	pause
	Clear-Host
}

$USERINFO = ConvertFrom-StringData (Get-Content -Raw $INFOPATH)
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
$UIAUTH = New-Object System.Management.Automation.PSCredential($UIUSER, ($UIPASS))

Write-Host (Get-Date) [ WebUI 目标主机为 $UIHOST ] -ForegroundColor Cyan

function Test-WebUIPort {
	while (!(Test-NetConnection $UIADDR -port $UIPORT -InformationLevel Quiet)) {
		Write-Host (Get-Date) [ BitComet WebUI 未开启，600 秒后重试 ] -ForegroundColor Yellow
		Start-Sleep 600
	}
}

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

$UIHOME = "http://$UIHOST"
while ($UIRESP.StatusCode -ne 200) {
	try {
		$UIRESP = Invoke-Webrequest -TimeoutSec 5 -Credential $UIAUTH $UIHOME -MaximumRedirection 0 -ErrorAction Ignore
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
			Write-Host (Get-Date) [ 网页返回代码 $UIRESP.StatusCode，10 分钟后重试 ] -ForegroundColor Yellow
			Start-Sleep 600
		}
	}
}


if ((Invoke-RestMethod -TimeoutSec 5 -Credential $UIAUTH $UIHOME) -Match 'BitComet') {
	Write-Host (Get-Date) [ BitComet WebUI 访问成功 ] -ForegroundColor Green
} else {
	Write-Host (Get-Date) [ 目标网页不是 BitComet WebUI，请重新配置 ] -ForegroundColor Red
	return
}

function Get-ErrorMessage {
	$streamReader = [System.IO.StreamReader]::new($Error[0].Exception.Response.GetResponseStream())
	$ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
	$streamReader.Close()
	if ($ErrResp.message) {Write-Host (Get-Date) [ $ErrResp.message ] -ForegroundColor Red}
}

function Get-QuadFloat {
	param ($PERCENT)
	if ($PERCENT -Match '100%') {
		$QUADFLOAT = "1"
	} else {
	$QUADFLOAT = ('0.' + ($PERCENT -Replace '%|\.') + '00').Substring(0,6)
	}
	Write-Output $QUADFLOAT
}

$CRC32 = add-type @"
[DllImport("ntdll.dll")]
public static extern uint RtlComputeCrc32(uint dwInitial, byte[] pData, int iLen);
"@ -Name CRC32 -PassThru
function Get-SaltedHash {
	param ($INFOHASH)
	$BYTE = [System.Text.Encoding]::UTF8.GetBytes($INFOHASH.ToLower())
	$SALT = ($CRC32::RtlComputeCrc32(0, $BYTE, $BYTE.Count)).ToString("x8")
	$SALT = $SALT.Substring(6,2) + $SALT.Substring(4,2) + $SALT.Substring(2,2) + $SALT.Substring(0,2)
	([System.BitConverter]::ToString(([System.Security.Cryptography.HashAlgorithm]::Create('SHA256')).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($INFOHASH + $SALT))) -Replace '-').ToLower()
}

function Get-BTNConfig {
	while ($RETRY -lt 3) {
		try {
			$NEWCONFIG = Invoke-RestMethod -TimeoutSec 30 -UserAgent $USERAGENT -Headers $AUTHHEADS $CONFIGURL
			$NEWCONFIG | ConvertTo-Json | Out-File $ENV:USERPROFILE\BTN_BC\CONFIG.json
			Write-Host (Get-Date) [ 获取 BTN 服务器配置成功，当前版本为 $NEWCONFIG.ability.reconfigure.version ] -ForegroundColor Green
			break
		} catch {
			Get-ErrorMessage
			Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
			if ($_.Exception.Response.StatusCode.value__ -Match '403|400') {
				Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，请排查后重试 ] -ForegroundColor Red
				exit
			}
			$RETRY++
			Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，600 秒后第 $RETRY 次重试 ] -ForegroundColor Yellow
			Start-Sleep 600
		}
	}
	if ($RETRY -ge 3) {
		if (Test-Path $ENV:USERPROFILE\BTN_BC\CONFIG.json) {
			Write-Host (Get-Date) [ 更新 BTN 服务器配置失败，使用上次获取的配置 ] -ForegroundColor Yellow
		} else {
			Write-Host (Get-Date) [ 获取 BTN 服务器配置失败，请确认服务器后重试 ] -ForegroundColor Red
			exit
		}
	}
	$Global:NEWCONFIG = Get-Content $ENV:USERPROFILE\BTN_BC\CONFIG.json | ConvertFrom-Json
}

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
	$PEERS -Split '<tr>' | Select-String '[IciC_]{4}' |% {
		if ($_ -Match '(\d{1,3}\.){3}\d{1,3}:\d{1,5}') {
			$ip_address = $Matches[0].Split(':')[0]
			$peer_port = $Matches[0].Split(':')[1]
		} elseif ($_ -Match '2[0-9a-f]{3}:([0-9a-f]{1,4}):(:?[0-9a-f]{1,4}:?){1,6}:\d{1,5}') {
			$ip_address = $Matches[0] -Replace ':[0-9]{1,5}$'
			$peer_port = ($Matches[0] -Split ':')[-1]
		} else {
			Write-Host (Get-Date) [ 提取了一个无法识别的地址：$_ ] -ForegroundColor Red
		}
		$_ -Match '(?<=>)[0-9a-f]{16}' | Out-Null
		$peer_id = -Join ($Matches[0] -Replace '(..)','[char]0x${0};'| Invoke-Expression)
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

function Get-PeersJson {
	Test-WebUIPort
	$ACTIVE = ((Invoke-RestMethod -TimeoutSec 5 -Credential $UIAUTH ${UIHOME}task_list) -Split '<.?tr>' -Replace '> (HTTPS|HTTP|FTP) <.*' -Split "'" | Select-String '.*action=stop') -Split '&|=' | Select-String '.*\d' |% {"${UIHOME}task_detail?id=" + $_}
	Write-Host (Get-Date) [ 当前 $ACTIVE.Count 个活动任务 ] -ForegroundColor Cyan
	$SUBMITHASH = @"
{
	"populate_time": $([DateTimeOffset]::Now.ToUnixTimeMilliseconds()),
	"peers": []
}
"@ | ConvertFrom-Json
	$ACTIVE |% {Get-TaskPeers (Invoke-RestMethod -Credential $UIAUTH $_) (Invoke-RestMethod -Credential $UIAUTH ${_}`&show=peers)}
	$SUBMITHASH | ConvertTo-Json | Out-File $PEERSJSON
	Write-Host (Get-Date) [ 分析 $($ACTIVE.Count) 个活动任务，提取 $($SUBMITHASH.peers.Count) 个活动 Peers，耗时 $((([DateTimeOffset]::Now.ToUnixTimeMilliseconds()) - $SUBMITHASH.populate_time) / 1000) 秒 ] -ForegroundColor Cyan
}

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
		Get-ErrorMessage
		Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
		Write-Host (Get-Date) [ 提交 Peers 快照失败，数据大小 $GZIPLENGTH KiB ] -ForegroundColor Yellow
	}
	Remove-Item $PEERSGZIP
}

$RULESJSON = "$ENV:USERPROFILE\BTN_BC\RULES.json"
$BTNIPLIST = "$ENV:USERPROFILE\BTN_BC\IPLIST.txt"
function Get-BTNRules {
	if ((Get-Content $RULESJSON -ErrorAction Ignore) -Match 'version') {
		$REVURL = "?rev=$(([Regex]::Matches(((Get-Content $RULESJSON -ErrorAction Ignore) | Select-String 'version'),'[0-9a-f]{8}')).Value)"
	}
	try {
		$RULESIWR = Invoke-Webrequest -TimeoutSec 30 -UserAgent $USERAGENT -Headers $AUTHHEADS ($NOWCONFIG.ability.rules.endpoint + $REVURL)
		if ($RULESIWR.Content.Length -eq 0) {return}
		$RULESOBJ = [system.Text.Encoding]::UTF8.GetString($RULESIWR.RawContentStream.ToArray()) | ConvertFrom-Json
		$RULESOBJ | ConvertTo-Json | Out-File $RULESJSON
		$RULESOBJ.IP.PSObject.Properties.value | Out-File $BTNIPLIST
		if (Get-NetFirewallDynamicKeywordAddress -Id $DYKWID -ErrorAction Ignore) {
			Update-NetFirewallDynamicKeywordAddress -Id $DYKWID -Addresses ((Get-Content $BTNIPLIST) -Join ',') | Out-Null
		} else {
		New-NetFirewallDynamicKeywordAddress -Id $DYKWID -Keyword "BTN_IPLIST" -Addresses ((Get-Content $BTNIPLIST) -Join ',') | Out-Null
		}
		Write-Host (Get-Date) [ 更新动态关键字成功，当前共 ((Get-NetFirewallDynamicKeywordAddress -Id $DYKWID).Addresses -Split ',').Count 条 IP 规则 ] -ForegroundColor Green
	} catch {
		Get-ErrorMessage
		Write-Host (Get-Date) [ $_ ] -ForegroundColor Red
		Write-Host (Get-Date) [ 更新动态关键字失败，当前共 ((Get-NetFirewallDynamicKeywordAddress -Id $DYKWID).Addresses -Split ',').Count 条 IP 规则 ] -ForegroundColor Yellow
	}
}

while ($True) {
	if (!$NOWCONFIG) {Get-BTNConfig}
	if (
		$NOWCONFIG.ability.submit_peers.interval -ne $NEWCONFIG.ability.submit_peers.interval -or
		$NOWCONFIG.ability.rules.interval -ne $NEWCONFIG.ability.rules.interval -or
		$NOWCONFIG.ability.reconfigure.interval -ne $NEWCONFIG.ability.reconfigure.interval
	) {
		$NOWCONFIG = Get-Content $ENV:USERPROFILE\BTN_BC\CONFIG.json | ConvertFrom-Json
		$NOWCONFIG.ability.PSObject.Properties.Name |% {
			$NOWCONFIG.ability.$_ | Add-Member next ((Get-Date) + (New-TimeSpan -Seconds ($NOWCONFIG.ability.$_.interval / 1000)))
		}
		$NOWCONFIG.ability.submit_peers | Add-Member cmd "Get-PeersJson; Invoke-SumbitPeers"
		$NOWCONFIG.ability.rules | Add-Member cmd "Get-BTNRules"
		$NOWCONFIG.ability.reconfigure | Add-Member cmd "Get-BTNConfig"
		Write-Host (Get-Date) [ BTNScriptBC 开始循环工作 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.submit_peers.interval / 1000) 秒提交 Peers 快照 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.rules.interval / 1000) 秒查询封禁规则更新 ] -ForegroundColor Cyan
		Write-Host (Get-Date) [ 每 $($NOWCONFIG.ability.reconfigure.interval / 1000) 秒查询 BTN 服务器配置更新 ] -ForegroundColor Cyan
	}
	$JOBLIST = $NOWCONFIG.ability.PSObject.Properties.Value | Sort-Object next
	if ($JOBLIST[0].cmd) {
		if ((Get-Date) -lt $JOBLIST[0].next) {Start-Sleep ($JOBLIST[0].next - (Get-Date)).Seconds}
		Invoke-Expression $JOBLIST[0].cmd
		$JOBLIST[0].next = ((Get-Date) + (New-TimeSpan -Seconds ($JOBLIST[0].interval / 1000)))
	}
}
