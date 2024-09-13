$USERPATH = "$ENV:USERPROFILE\BTNScriptBC"
$LINKPATH = "$USERPATH\BTNScriptBC.lnk"
$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($LINKPATH)
$Shortcut.TargetPath = "$USERPATH\STARTUP.cmd"
$Shortcut.IconLocation = "$ENV:WINDIR\System32\EaseOfAccessDialog.exe"
$Shortcut.Save()
$LINKBYTE = [System.IO.File]::ReadAllBytes($LINKPATH)
$LINKBYTE[0x15] = $LINKBYTE[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($LINKPATH,$LINKBYTE)
Copy-Item $LINKPATH $([Environment]::GetFolderPath("Desktop"))
Write-Host "`n  已配置桌面快捷方式：BTNScriptBC.lnk`n"
