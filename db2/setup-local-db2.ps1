# =============================================================
# EMUNAH BANK LAB - Setup Db2 Local (Windows)
# =============================================================
# PRE-REQUISITO: IBM Db2 Community Edition instalado
# Download: https://www.ibm.com/db2/trials
# Apos instalar, abra o "DB2 Command Window" como Administrador
# e execute este script:
#   powershell -ExecutionPolicy Bypass -File setup-local-db2.ps1
# =============================================================

$DB2_EXE  = "db2"          # ja deve estar no PATH apos instalar o Db2
$DATABASE = "EMUNAH"
$SCHEMA   = "EMUNAH"
$DDL_FILE = "$PSScriptRoot\EMUNAH-DDL.sql"

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  EMUNAH BANK LAB - Setup Db2 Local"   -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Criar o banco de dados ---
Write-Host "[1/4] Criando banco de dados '$DATABASE'..." -ForegroundColor Yellow
& $DB2_EXE "CREATE DATABASE $DATABASE USING CODESET UTF-8 TERRITORY BR COLLATE USING SYSTEM PAGESIZE 32768"
if ($LASTEXITCODE -ne 0) {
    Write-Host "      Banco ja existe ou erro na criacao (verificar acima). Continuando..." -ForegroundColor DarkYellow
}

# --- 2. Conectar ao banco ---
Write-Host "[2/4] Conectando ao banco '$DATABASE'..." -ForegroundColor Yellow
& $DB2_EXE "CONNECT TO $DATABASE"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Nao foi possivel conectar. Verifique se o Db2 esta rodando." -ForegroundColor Red
    exit 1
}

# --- 3. Criar o schema ---
Write-Host "[3/4] Criando schema '$SCHEMA'..." -ForegroundColor Yellow
& $DB2_EXE "CREATE SCHEMA $SCHEMA"
if ($LASTEXITCODE -ne 0) {
    Write-Host "      Schema ja existe ou sera criado automaticamente. Continuando..." -ForegroundColor DarkYellow
}

# --- 4. Executar o DDL ---
Write-Host "[4/4] Executando DDL: $DDL_FILE" -ForegroundColor Yellow
if (-not (Test-Path $DDL_FILE)) {
    Write-Host "ERRO: Arquivo DDL nao encontrado em: $DDL_FILE" -ForegroundColor Red
    exit 1
}
& $DB2_EXE "-tvf `"$DDL_FILE`""

Write-Host ""
Write-Host "=======================================" -ForegroundColor Green
Write-Host "  Setup concluido!"                     -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Para verificar:" -ForegroundColor Cyan
Write-Host "  db2 connect to $DATABASE"
Write-Host "  db2 `"SELECT COUNT(*) FROM $SCHEMA.CLIENTES`""
Write-Host "  db2 `"SELECT COUNT(*) FROM $SCHEMA.CONTAS`""
Write-Host ""
Write-Host "Para abrir o Db2 Command Line:" -ForegroundColor Cyan
Write-Host "  Menu Iniciar > IBM Db2 > DB2 Command Line Processor"
Write-Host ""
