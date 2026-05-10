@echo off
:: EBOPS CLI Launcher
:: Duplo clique neste arquivo para abrir o EBOPS no PowerShell

cd /d "%~dp0"

:: Verifica se o pwsh (PowerShell 7+) existe, senão usa o powershell.exe (5.x)
where pwsh >nul 2>nul
if %errorlevel% == 0 (
    pwsh.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0ebops-cli.ps1"
) else (
    powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0ebops-cli.ps1"
)
