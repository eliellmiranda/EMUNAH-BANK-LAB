# ==============================================================
# EMUNAH BANK LAB — BACKUP COMPLETO DO MAINFRAME PARA LOCAL
# ==============================================================
# Uso: .\eb-backup.ps1
# Prerequisito: Zowe CLI configurado e autenticado (zowe config)
# Cria estrutura de pastas e baixa tudo de Z77948.EMUNAH.*
# VSAM (KSDS/ESDS) e GDG precisam de REPRO no mainframe antes.
# ==============================================================

$HLQ     = "Z77948"
$PROJETO = "EMUNAH"
$BASE    = "$HLQ.$PROJETO"
$DATA    = Get-Date -Format "yyyyMMdd_HHmmss"
$DESTINO = ".\backup\$DATA"

Write-Host ""
Write-Host "======================================================"
Write-Host "  EMUNAH BANK LAB - BACKUP REMOTO -> LOCAL"
Write-Host "  HLQ  : $BASE"
Write-Host "  DEST : $DESTINO"
Write-Host "  DATA : $DATA"
Write-Host "======================================================"
Write-Host ""

# --------------------------------------------------------------
# Cria estrutura de diretórios
# --------------------------------------------------------------
$dirs = @(
    "$DESTINO\dev\cobol",
    "$DESTINO\dev\jcl",
    "$DESTINO\dev\copy",
    "$DESTINO\dev\rexx",
    "$DESTINO\hml\cobol",
    "$DESTINO\hml\jcl",
    "$DESTINO\prd\jcl",
    "$DESTINO\seed",
    "$DESTINO\arq\seq",
    "$DESTINO\arq\vsam-flat"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Write-Host "[OK] Estrutura de diretorios criada em $DESTINO"
Write-Host ""

# --------------------------------------------------------------
# Funcao auxiliar: baixa PDS e reporta resultado
# --------------------------------------------------------------
function Download-PDS {
    param($dataset, $destDir, $ext)
    Write-Host "--> PDS: $dataset"
    zowe zos-files download all-members "$dataset" `
        --directory "$destDir" `
        --extension "$ext" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $count = (Get-ChildItem "$destDir" -Filter "*$ext" -ErrorAction SilentlyContinue).Count
        Write-Host "    [OK] $count membro(s) baixado(s) em $destDir"
    } else {
        Write-Host "    [AVISO] Falha ou dataset inexistente: $dataset"
    }
    Write-Host ""
}

# --------------------------------------------------------------
# Funcao auxiliar: baixa dataset sequencial
# --------------------------------------------------------------
function Download-SEQ {
    param($dataset, $destFile)
    Write-Host "--> SEQ: $dataset"
    zowe zos-files download data-set "$dataset" `
        --file "$destFile" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Salvo em $destFile"
    } else {
        Write-Host "    [AVISO] Falha ou dataset inexistente: $dataset"
    }
    Write-Host ""
}

# ==============================================================
# BLOCO 1 - BIBLIOTECAS DEV (fontes, JCL, copybooks, REXX)
# ==============================================================
Write-Host ">>> BLOCO 1: BIBLIOTECAS DEV"
Write-Host "------------------------------------------------------"

Download-PDS "$BASE.DEV.COBOL" "$DESTINO\dev\cobol" ".cbl"
Download-PDS "$BASE.DEV.JCL"   "$DESTINO\dev\jcl"   ".jcl"
Download-PDS "$BASE.DEV.COPY"  "$DESTINO\dev\copy"  ".cpy"
Download-PDS "$BASE.DEV.REXX"  "$DESTINO\dev\rexx"  ".rexx"

# LOADLIB nao e baixado (modulos compilados nao tem utilidade local)
Write-Host "    [INFO] DEV.LOADLIB ignorado — modulos compilados nao sao fonte"
Write-Host ""

# ==============================================================
# BLOCO 2 - BIBLIOTECAS HML
# ==============================================================
Write-Host ">>> BLOCO 2: BIBLIOTECAS HML"
Write-Host "------------------------------------------------------"

Download-PDS "$BASE.HML.COBOL" "$DESTINO\hml\cobol" ".cbl"
Download-PDS "$BASE.HML.JCL"   "$DESTINO\hml\jcl"   ".jcl"

Write-Host "    [INFO] HML.LOADLIB ignorado — modulos compilados nao sao fonte"
Write-Host ""

# ==============================================================
# BLOCO 3 - BIBLIOTECAS PRD
# ==============================================================
Write-Host ">>> BLOCO 3: BIBLIOTECAS PRD"
Write-Host "------------------------------------------------------"

Download-PDS "$BASE.PRD.JCL"     "$DESTINO\prd\jcl"     ".jcl"
Download-PDS "$BASE.PRD.PARMLIB" "$DESTINO\prd\parmlib" ".prm"

Write-Host "    [INFO] PRD.LOADLIB ignorado — modulos compilados nao sao fonte"
Write-Host ""

# ==============================================================
# BLOCO 4 - ARQUIVOS DE SEED
# ==============================================================
Write-Host ">>> BLOCO 4: SEED DATA"
Write-Host "------------------------------------------------------"

Download-SEQ "$BASE.SEED.CLIENTES.SEQ" "$DESTINO\seed\clientes.txt"
Download-SEQ "$BASE.SEED.CONTAS.SEQ"   "$DESTINO\seed\contas.txt"

# ==============================================================
# BLOCO 5 - ARQUIVOS SEQUENCIAIS DE NEGOCIO (ARQ)
# ==============================================================
Write-Host ">>> BLOCO 5: ARQUIVOS SEQUENCIAIS DE NEGOCIO"
Write-Host "------------------------------------------------------"

Download-SEQ "$BASE.ARQ.ENTRADA.SEQ"    "$DESTINO\arq\seq\entrada.txt"
Download-SEQ "$BASE.ARQ.REJEITO.SEQ"    "$DESTINO\arq\seq\rejeito.txt"
Download-SEQ "$BASE.ARQ.AUDIT.SEQ"      "$DESTINO\arq\seq\audit.txt"
Download-SEQ "$BASE.ARQ.SALDO.SEQ"      "$DESTINO\arq\seq\saldo_in.txt"
Download-SEQ "$BASE.ARQ.SALDO.OUT.SEQ"  "$DESTINO\arq\seq\saldo_out.txt"

# ==============================================================
# BLOCO 6 - VSAM / GDG (flat gerado por REPRO no mainframe)
# ==============================================================
Write-Host ">>> BLOCO 6: VSAM FLAT (gerado via REPRO) e GDG"
Write-Host "------------------------------------------------------"
Write-Host "    [INFO] KSDS e ESDS nao podem ser baixados diretamente."
Write-Host "    [INFO] Execute o JCL de REPRO no mainframe primeiro:"
Write-Host "           IDCAMS REPRO de ARQ.CLIENTE.KSDS -> ARQ.CLIENTE.FLAT"
Write-Host "           IDCAMS REPRO de ARQ.CONTA.KSDS   -> ARQ.CONTA.FLAT"
Write-Host "           IDCAMS REPRO de ARQ.SALDO.KSDS   -> ARQ.SALDO.FLAT"
Write-Host "           IDCAMS REPRO de ARQ.LANCTO.ESDS  -> ARQ.LANCTO.FLAT"
Write-Host "    [INFO] Depois rode os comandos abaixo manualmente:"
Write-Host ""
Write-Host "    zowe zos-files download data-set `"$BASE.ARQ.CLIENTE.FLAT`" --file `"$DESTINO\arq\vsam-flat\cliente.txt`""
Write-Host "    zowe zos-files download data-set `"$BASE.ARQ.CONTA.FLAT`"   --file `"$DESTINO\arq\vsam-flat\conta.txt`""
Write-Host "    zowe zos-files download data-set `"$BASE.ARQ.SALDO.FLAT`"   --file `"$DESTINO\arq\vsam-flat\saldo.txt`""
Write-Host "    zowe zos-files download data-set `"$BASE.ARQ.LANCTO.FLAT`"  --file `"$DESTINO\arq\vsam-flat\lancto.txt`""
Write-Host ""

# GDG — baixa geracao mais recente (G0001V00)
Write-Host "    [INFO] Para GDG (extrato), identifique a geracao ativa com:"
Write-Host "           zowe zos-files list data-set `"$BASE.ARQ.EXTRATO.GDG`""
Write-Host "    [INFO] Depois baixe cada geracao desejada com:"
Write-Host "           zowe zos-files download data-set `"$BASE.ARQ.EXTRATO.GDG(G0001V00)`" --file `"$DESTINO\arq\seq\extrato_g0001.txt`""
Write-Host ""

# ==============================================================
# RESUMO FINAL
# ==============================================================
Write-Host "======================================================"
Write-Host "  BACKUP CONCLUIDO"
Write-Host "  Diretorio: $DESTINO"
Write-Host ""
Write-Host "  PENDENTES (requerem acao manual no mainframe):"
Write-Host "    - VSAM KSDS: ARQ.CLIENTE, ARQ.CONTA, ARQ.SALDO"
Write-Host "    - VSAM ESDS: ARQ.LANCTO"
Write-Host "    - GDG      : ARQ.EXTRATO (identificar geracoes ativas)"
Write-Host "======================================================"
Write-Host ""
