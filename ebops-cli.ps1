# ==============================================================================
# EBOPS LITE - Emunah Bank Lab Backend Developer CLI
# ==============================================================================

$HLQ_JCL = "Z77948.EMUNAH.DEV.JCL"
$HLQ_COBOL = "Z77948.EMUNAH.DEV.COBOL"
$HLQ_ENTRADA = "Z77948.EMUNAH.DEV.ENTRADA" # Ajuste para o seu PDS/PS de entrada
$PROGRAMA_CATALOGO = "EBCATALG"            # Nome do programa que sofrerá injeção
$ARQUIVO_LOCAL_TEMP = "temp_$PROGRAMA_CATALOGO.cbl"

# Definição de 5 Injeções (Defeitos intencionais para gerar demanda)
# Formato: @{ Nome = "Descrição"; Original = "Código Certo"; Injetado = "Código com Bug" }
$Injecoes = @(
    @{ Id=1; Desc="Zera a taxa de operacao"; Busca="MOVE 0.05 TO WS-TAXA"; Troca="MOVE 0.00 TO WS-TAXA" },
    @{ Id=2; Desc="Rejeita contas ativas"; Busca="IF ST-CONTA = 'A'"; Troca="IF ST-CONTA = 'X'" },
    @{ Id=3; Desc="Limite de transacao muito baixo"; Busca="IF WS-VALOR > 5000"; Troca="IF WS-VALOR > 0050" },
    @{ Id=4; Desc="Muda File Status esperado de sucesso"; Busca="IF WS-FS-LANC = '00'"; Troca="IF WS-FS-LANC = '10'" },
    @{ Id=5; Desc="Inverte validacao de data (Causa abend em sort)"; Busca="MOVE WS-ANO-MES-DIA TO DB-DATA"; Troca="MOVE WS-DIA-MES-ANO TO DB-DATA" }
)

function Executar-Job {
    param([string]$NomeJcl)
    Write-Host "[EBOPS] Submetendo $NomeJcl e aguardando conclusao (--wfo)..." -ForegroundColor Cyan
    # O parametro --wfo garante que o script so continua quando o JCL terminar no TK5
    zowe zos-jobs submit data-set "$HLQ_JCL($NomeJcl)" --wfo
}

function Realizar-Injecao {
    Write-Host "`n[EBOPS] --- INICIANDO INJECAO DE DEMANDA ---" -ForegroundColor Yellow
    
    # Sorteia uma injeção aleatória das 5 disponíveis
    $Injecao = $Injecoes | Get-Random
    Write-Host "[EBOPS] Demanda gerada: $($Injecao.Desc)" -ForegroundColor Magenta

    Write-Host "[EBOPS] Baixando codigo fonte: $HLQ_COBOL($PROGRAMA_CATALOGO)..."
    zowe zos-files download data-set "$HLQ_COBOL($PROGRAMA_CATALOGO)" -f $ARQUIVO_LOCAL_TEMP | Out-Null

    Write-Host "[EBOPS] Alterando catalogo (Injetando defeito)..."
    $Conteudo = Get-Content $ARQUIVO_LOCAL_TEMP
    $ConteudoModificado = $Conteudo -replace $Injecao.Busca, $Injecao.Troca
    $ConteudoModificado | Set-Content $ARQUIVO_LOCAL_TEMP

    Write-Host "[EBOPS] Fazendo upload do codigo alterado..."
    zowe zos-files upload file-to-data-set $ARQUIVO_LOCAL_TEMP "$HLQ_COBOL($PROGRAMA_CATALOGO)" | Out-Null

    Remove-Item $ARQUIVO_LOCAL_TEMP
    Write-Host "[EBOPS] Injecao concluida com sucesso!" -ForegroundColor Green
}

function Submeter-Seed {
    param([string]$Dia)
    Write-Host "`n[EBOPS] --- PREPARANDO SEED DE LANCAMENTOS ---" -ForegroundColor Yellow
    $CaminhoArquivo = ".\EMUNAH-BANK-LAB\data\entrada\lancamento-d$Dia.txt"
    
    if (Test-Path $CaminhoArquivo) {
        Write-Host "[EBOPS] Subindo arquivo de carga: $CaminhoArquivo"
        # Supondo que a entrada seja um PS (Sequential Dataset) ou membro de PDS. Ajuste conforme sua arquitetura.
        zowe zos-files upload file-to-data-set $CaminhoArquivo "$HLQ_ENTRADA(LANCD$Dia)" | Out-Null
        Write-Host "[EBOPS] Arquivo de seed carregado!" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Arquivo $CaminhoArquivo nao encontrado! O Job pode falhar por falta de dados." -ForegroundColor Red
    }
}

function Gerar-Dia {
    $Dia = Read-Host "Digite o numero do dia (ex: 15)"
    
    Write-Host "`n======================================================="
    Write-Host " INICIANDO PROCESSAMENTO DO DIA $Dia"
    Write-Host "======================================================="

    # Passo 1: Reset do ambiente
    Executar-Job "EBRESET"

    # Passo 2: Injeção de catálogo (baixa, altera, reupa)
    Realizar-Injecao

    # Passo 3: Subir seed de lançamentos do dia
    Submeter-Seed $Dia

    # Passo 4: Deploy (Compilação dos programas alterados)
    Executar-Job "EBDEPLOY"

    # Passo 5: Rodar a cadeia Batch
    Write-Host "`n[EBOPS] --- EXECUTANDO CADEIA BATCH ---" -ForegroundColor Yellow
    Executar-Job "EBJCHAIN"

    Write-Host "`n======================================================="
    Write-Host " DIA $Dia CONCLUIDO! Va investigar o output da cadeia." -ForegroundColor Green
    Write-Host "=======================================================`n"
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================
do {
    Write-Host " "
    Write-Host "==================== EBOPS LITE ====================" -ForegroundColor Cyan
    Write-Host "1. Gerar Dia (Reset -> Injecao -> Seed -> Deploy -> Chain)"
    Write-Host "2. Sair"
    Write-Host "====================================================" -ForegroundColor Cyan
    $Opcao = Read-Host "Escolha uma opcao"

    switch ($Opcao) {
        "1" { Gerar-Dia }
        "2" { Write-Host "Saindo..."; break }
        default { Write-Host "Opcao invalida." -ForegroundColor Red }
    }
} while ($Opcao -ne "2")