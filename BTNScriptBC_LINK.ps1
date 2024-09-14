$USERPATH = "$ENV:USERPROFILE\BTNScriptBC"
if (!(Test-Path $USERPATH\STARTUP.cmd)) {Write-Host `n  未配置 BTNScriptBC`n; return}
if ((Get-Content $USERPATH\STARTUP.cmd) -Match 'nofw') {$NOFW = 1}
$LINKPATH = "$USERPATH\BTNScriptBC.lnk"
if ($NOFW) {$LINKPATH = "$USERPATH\BTNScriptBC_nofw.lnk"}
$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($LINKPATH)
$Shortcut.TargetPath = "$USERPATH\STARTUP.cmd"
$Shortcut.IconLocation = "$ENV:WINDIR\System32\EaseOfAccessDialog.exe"
$Shortcut.Save()
if (!$NOFW) {
	$LINKBYTE = [System.IO.File]::ReadAllBytes($LINKPATH)
	$LINKBYTE[0x15] = $LINKBYTE[0x15] -bor 0x20
	[System.IO.File]::WriteAllBytes($LINKPATH,$LINKBYTE)
}
Copy-Item $LINKPATH $([Environment]::GetFolderPath("Desktop"))
Write-Host "`n  已配置桌面快捷方式：$($LINKPATH.Split('\')[-1])`n"
