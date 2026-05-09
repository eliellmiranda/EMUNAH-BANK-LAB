# Inicia o Emunah Bank Lab Web UI
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Emunah Bank Lab - Interface Web" -ForegroundColor Cyan
Write-Host "Iniciando servidor em http://localhost:5001" -ForegroundColor Green
Write-Host "Pressione Ctrl+C para parar." -ForegroundColor Yellow
python "$ScriptDir\app.py"
