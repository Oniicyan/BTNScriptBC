$USERPATH = "$ENV:USERPROFILE\BTNScriptBC"
$LINKPATH = "$([Environment]::GetFolderPath("Desktop"))\BTNScriptBC.lnk"
$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$([Environment]::GetFolderPath("Desktop"))\BTNScriptBC.lnk")
$Shortcut.TargetPath = "$USERPATH\STARTUP.cmd"
$Shortcut.IconLocation = "$ENV:WINDIR\System32\EaseOfAccessDialog.exe"
$Shortcut.Save()
$LINKBYTE = [System.IO.File]::ReadAllBytes($Shortcut.FullName)
$LINKBYTE[0x15] = $LINKBYTE[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($Shortcut.FullName,$LINKBYTE)
Write-Host "`n  已配置桌面快捷方式：BTNScriptBC.lnk`n"
