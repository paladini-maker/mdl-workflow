@echo off
setlocal EnableExtensions
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "tools\windows\Invoke-YorhaBuild.ps1" %*
exit /b %ERRORLEVEL%
