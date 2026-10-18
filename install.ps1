# install.ps1 — Windows PowerShell installer for agy-quota-guard
$ErrorActionPreference = "Stop"

$SrcDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = if ($env:AGY_PLUGIN_INSTALL_DIR) {
    [System.IO.Path]::GetFullPath($env:AGY_PLUGIN_INSTALL_DIR)
} else {
    Join-Path $HOME ".agents\plugins\agy-quota-guard"
}
$BinDir = if ($env:AGY_BIN_INSTALL_DIR) {
    [System.IO.Path]::GetFullPath($env:AGY_BIN_INSTALL_DIR)
} else {
    Join-Path $HOME ".local\bin"
}

New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir "scripts") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir "bin") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir "locales") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir "templates") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir "shell") | Out-Null
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

Copy-Item (Join-Path $SrcDir "plugin.json") (Join-Path $TargetDir "plugin.json") -Force
Copy-Item (Join-Path $SrcDir "hooks.json") (Join-Path $TargetDir "hooks.json") -Force
Copy-Item (Join-Path $SrcDir "scripts\*.py") (Join-Path $TargetDir "scripts\") -Force
Copy-Item (Join-Path $SrcDir "bin\*") (Join-Path $TargetDir "bin\") -Force
Copy-Item (Join-Path $SrcDir "locales\*.json") (Join-Path $TargetDir "locales\") -Force
Copy-Item (Join-Path $SrcDir "templates\progress.md") (Join-Path $TargetDir "templates\progress.md") -Force
Copy-Item (Join-Path $SrcDir "shell\*") (Join-Path $TargetDir "shell\") -Force

$CmdShim = @"
@echo off
setlocal
if not defined AGY_QUOTA_GUARD_HOME set "AGY_QUOTA_GUARD_HOME=$TargetDir"
call "%AGY_QUOTA_GUARD_HOME%\bin\agy-run.cmd" %*
exit /b %ERRORLEVEL%
"@
Set-Content -Path (Join-Path $BinDir "agy-run.cmd") -Value $CmdShim -Encoding Ascii

$ShTarget = $TargetDir.Replace('\', '/')
$ShShim = @"
#!/usr/bin/env bash
export AGY_QUOTA_GUARD_HOME="`$:AGY_QUOTA_GUARD_HOME:-$ShTarget}"
exec "`$AGY_QUOTA_GUARD_HOME/bin/agy-run" "`$@"
"@
$ShShim = $ShShim.Replace('`$:AGY_QUOTA_GUARD_HOME', '${AGY_QUOTA_GUARD_HOME')
Set-Content -Path (Join-Path $BinDir "agy-run") -Value $ShShim -Encoding Utf8

Write-Host "Installed agy-quota-guard to: $TargetDir"
Write-Host "Installed launcher to:        $BinDir\agy-run.cmd"
