# ==============================================================================
# EBOPS CLI - Emunah Bank Lab Backend Developer
# Versao 2.3 - job streaming direto, diagnostico B, sem spoilers
# ==============================================================================

$HLQ_JCL     = "ELIEL.EMUNAH.DEV.JCL"
$HLQ_COBOL   = "ELIEL.EMUNAH.DEV.COBOL"
$HLQ_COPY    = "ELIEL.EMUNAH.DEV.COPY"
$HLQ_ENTRADA = "ELIEL.EMUNAH.STAGE.ENTRADA.SEQ"
$ARQUIVO_LOCAL_TEMP = "temp_injecao.txt"

$BASE_DIR         = Split-Path $PSScriptRoot -Parent
$SCRIPT_PYTHON    = Join-Path $BASE_DIR "automation\geracao\gerar_lancamentos.py"
$BACKUP_DIR       = Join-Path $BASE_DIR "backup_emunah"
$ARQUIVO_INJECOES = Join-Path $BASE_DIR "ebops\data\injecoes.json"
$ESTADO_FILE      = Join-Path $BASE_DIR "ebops\data\estado.json"

# ==============================================================================
# LISTAS DE ARQUIVOS PERMITIDOS (TRAVA DE SEGURANCA)
# ==============================================================================
$AllowedCOBOL = @("EBCTL01","EBVALI01","EBPOST01","EBACCR01","EBSNAP01","EBCONC01","EBEXTR01","EBJEOD01")
$AllowedCOPY  = @("CPLCT001","CPCNT001","CPAUD001","CPREJ001","CPSNP001","CPCNC001","CPEXT001","CPSTS001")
$AllowedJCL   = @("EBJPRECK","EBJSOD","EBJBCKPD","EBJWAIT","EBJLOAD","EBJVALD","EBJRPOST","EBJCUTE","EBJCUTF","EBJACCR","EBJSNAP","EBJCONC","EBJEXTR","EBJEOD")

# ==============================================================================
# FUNCOES DE ESTADO
# ==============================================================================

function Carregar-Estado {
    if (Test-Path $ESTADO_FILE) {
        try {
            $json = Get-Content $ESTADO_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
            return @{
                injecoes_ativas = @($json.injecoes_ativas)
                historico       = @($json.historico)
            }
        } catch {
            Write-Host "[AVISO] Falha ao ler estado.json - iniciando estado vazio." -ForegroundColor Yellow
        }
    }
    return @{ injecoes_ativas = @(); historico = @() }
}

function Salvar-Estado {
    param($Estado)
    $Dir = Split-Path $ESTADO_FILE -Parent
    if (-not (Test-Path $Dir)) { New-Item -ItemType Directory -Force -Path $Dir | Out-Null }
    $Estado | ConvertTo-Json -Depth 10 | Set-Content $ESTADO_FILE -Encoding UTF8
}

# ==============================================================================
# FUNCOES CORE
# ==============================================================================

function Executar-Job {
    param([string]$NomeJcl)

    Write-Host "`n[EBOPS] Submetendo " -ForegroundColor Cyan -NoNewline
    Write-Host $NomeJcl -ForegroundColor Red -NoNewline
    Write-Host " e aguardando conclusao (--wfo)..." -ForegroundColor Cyan
    Write-Host ""

    # Chamada direta sem captura nem pipeline:
    # o Zowe escreve no console em tempo real, mostrando jobid e andamento.
    # Capturar em variavel ou usar | ForEach-Object faz o Zowe detectar que
    # stdout nao e um terminal e desativa o output progressivo.
    & zowe zos-jobs submit data-set "$HLQ_JCL($NomeJcl)" --wfo

    Write-Host ""
    Write-Host "[EBOPS] Job " -ForegroundColor Green -NoNewline
    Write-Host $NomeJcl -ForegroundColor Red -NoNewline
    Write-Host " concluido!" -ForegroundColor Green
}

function Realizar-Backup {
    Write-Host "`n[EBOPS] --- INICIANDO BACKUP ---" -ForegroundColor Yellow
    Write-Host "[EBOPS] Baixando datasets para $BACKUP_DIR..."
    & zowe zos-files download data-sets-matching "ELIEL.EMUNAH.**" --directory "$BACKUP_DIR" --fail-fast false
    Write-Host "[EBOPS] Backup concluido!" -ForegroundColor Green
}

function Gerar-MassaLancamentos {
    Write-Host "`n[EBOPS] --- GERANDO MASSA DE DADOS (PYTHON) ---" -ForegroundColor Yellow
    $Dia = Read-Host "Digite o numero do dia (ex: 15)"
    $Qtd = Read-Host "Quantidade de lancamentos (ex: 100)"
    $CaminhoSaida = Join-Path $BASE_DIR "data\entrada\lancamentos-d$Dia.txt"
    $AnoMes   = (Get-Date).ToString("yyyyMM")
    $DataFull = $AnoMes + $Dia.PadLeft(2, '0')
    Write-Host "[EBOPS] Executando gerador Python..."
    python "$SCRIPT_PYTHON" --quantidade $Qtd --output "$CaminhoSaida" --data $DataFull
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[EBOPS] Arquivo gerado em: $CaminhoSaida" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Verifique o caminho: $SCRIPT_PYTHON" -ForegroundColor Red
    }
}

function Submeter-Seed {
    Write-Host "`n[EBOPS] --- PREPARANDO SEED DE LANCAMENTOS ---" -ForegroundColor Yellow
    $Dia = Read-Host "Digite o numero do dia (ex: 15)"
    $CaminhoArquivo = Join-Path $BASE_DIR "data\entrada\lancamentos-d$Dia.txt"
    if (Test-Path $CaminhoArquivo) {
        Write-Host "[EBOPS] Subindo carga: $CaminhoArquivo"
        & zowe zos-files upload file-to-data-set "$CaminhoArquivo" "$HLQ_ENTRADA(LANCD$Dia)"
        Write-Host "[EBOPS] Seed carregado no mainframe!" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Arquivo nao encontrado: $CaminhoArquivo" -ForegroundColor Red
    }
}

# ==============================================================================
# EXIBICAO DE TICKET (somente sintoma - sem membro, tipo ou causa)
# ==============================================================================

function Exibir-Ticket {
    param($Injecao)
    $Sep      = "-" * 58
    $DataHora = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $CorSev   = switch ($Injecao.SeveridadeTicket) {
        "critica" { "Red" }; "alta" { "Yellow" }; "media" { "Cyan" }; default { "Green" }
    }
    Write-Host ""
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host "  TICKET SIMULADO - EBOPS" -ForegroundColor Yellow
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host "  Abertura   : " -NoNewline -ForegroundColor Gray; Write-Host $DataHora -ForegroundColor White
    Write-Host "  Severidade : " -NoNewline -ForegroundColor Gray
    Write-Host $Injecao.SeveridadeTicket.ToUpper() -ForegroundColor $CorSev
    Write-Host "  Camada     : " -NoNewline -ForegroundColor Gray
    Write-Host "$($Injecao.CamadaFalha) | $($Injecao.AbendOuRC)" -ForegroundColor White
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host "  SINTOMA REPORTADO:" -ForegroundColor Yellow
    Write-Host ""
    $Palavras = $Injecao.SintomaTicket -split " "
    $Linha = "  "
    foreach ($p in $Palavras) {
        if (($Linha + $p).Length -gt 66) { Write-Host $Linha -ForegroundColor White; $Linha = "  $p " }
        else { $Linha += "$p " }
    }
    if ($Linha.Trim().Length -gt 0) { Write-Host $Linha -ForegroundColor White }
    Write-Host ""
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host "  [i] Para revelar a dica de diagnostico use a opcao A do menu." -ForegroundColor DarkGray
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host ""
}

# ==============================================================================
# STATUS ADMIN (detalhes tecnicos + dica)
# ==============================================================================

function Exibir-Status-Injecoes {
    $Estado = Carregar-Estado
    $Ativos = $Estado.injecoes_ativas
    $Sep    = "-" * 58
    Write-Host ""; Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host "  STATUS ADMIN - INJECOES ATIVAS" -ForegroundColor Yellow
    Write-Host "  $Sep" -ForegroundColor DarkGray
    if (-not $Ativos -or $Ativos.Count -eq 0) {
        Write-Host "  Nenhuma injecao ativa no momento." -ForegroundColor DarkGray
    } else {
        Write-Host "  Ativas: $($Ativos.Count)" -ForegroundColor Cyan; Write-Host ""
        foreach ($a in $Ativos) {
            Write-Host "  [#$($a.Id)] " -NoNewline -ForegroundColor Yellow
            Write-Host $a.Titulo -ForegroundColor White
            Write-Host "         Alvo  : $($a.TipoDataset)($($a.Membro))" -ForegroundColor DarkGray
            Write-Host "         Causa : $($a.Descricao)" -ForegroundColor DarkGray
            Write-Host "         Desde : $($a.Timestamp)" -ForegroundColor DarkGray
            Write-Host ""
        }
    }
    if ($Estado.historico -and $Estado.historico.Count -gt 0) {
        Write-Host "  Historico (revertidas): $($Estado.historico.Count)" -ForegroundColor DarkGray
    }
    Write-Host "  $Sep" -ForegroundColor DarkGray
    if ($Ativos -and $Ativos.Count -gt 0) {
        $IdDica = Read-Host "`n[EBOPS] Revelar dica para qual injecao? [ID ou Enter para pular]"
        if ($IdDica -ne "" -and (Test-Path $ARQUIVO_INJECOES)) {
            $inj = (Get-Content $ARQUIVO_INJECOES | ConvertFrom-Json) |
                   Where-Object { $_.Id -eq [int]$IdDica }
            if ($inj) {
                Write-Host ""; Write-Host "  DICA - #$($inj.Id) [$($inj.Titulo)]:" -ForegroundColor Cyan
                Write-Host ""
                $Palavras = $inj.Dica -split " "; $Linha = "  "
                foreach ($p in $Palavras) {
                    if (($Linha + $p).Length -gt 66) { Write-Host $Linha -ForegroundColor White; $Linha = "  $p " }
                    else { $Linha += "$p " }
                }
                if ($Linha.Trim().Length -gt 0) { Write-Host $Linha -ForegroundColor White }
                Write-Host ""
            } else { Write-Host "[AVISO] Injecao #$IdDica nao encontrada." -ForegroundColor Yellow }
        }
    }
}

# ==============================================================================
# DIAGNOSTICO B - inspeciona o conteudo real de cada membro
# ==============================================================================

function Diagnosticar-Injecoes {
    Write-Host "`n[EBOPS] --- DIAGNOSTICO DE STRINGS (OPCAO B) ---" -ForegroundColor Yellow
    Write-Host "[EBOPS] Baixando cada membro e comparando com o injecoes.json..." -ForegroundColor DarkGray
    Write-Host ""

    if (-not (Test-Path $ARQUIVO_INJECOES)) {
        Write-Host "[ERRO] injecoes.json nao encontrado." -ForegroundColor Red; return
    }

    $Injecoes = Get-Content $ARQUIVO_INJECOES | ConvertFrom-Json
    $Sep = "-" * 58

    foreach ($inj in $Injecoes) {
        Write-Host "  $Sep" -ForegroundColor DarkGray
        Write-Host "  [#$($inj.Id)] $($inj.Titulo)" -ForegroundColor Cyan
        Write-Host "         Membro : $($inj.TipoDataset)($($inj.Membro))" -ForegroundColor DarkGray

        if (-not (Validar-MembroPermitido -Tipo $inj.TipoDataset -Membro $inj.Membro)) {
            Write-Host "         [IGNORADO] Membro nao esta na allowlist." -ForegroundColor DarkGray
            continue
        }

        $HLQ_Alvo      = Obter-HLQ -Tipo $inj.TipoDataset
        $DatasetMembro = "$HLQ_Alvo($($inj.Membro))"
        $TempFile      = "diag_$($inj.Id).txt"

        & zowe zos-files download data-set $DatasetMembro -f $TempFile 2>&1 | Out-Null

        if (-not (Test-Path $TempFile)) {
            Write-Host "         [ERRO] Falha no download." -ForegroundColor Red; continue
        }

        $Linhas   = Get-Content $TempFile
        $Conteudo = $Linhas -join "`n"

        # --- Verifica string Original ---
        if ($Conteudo -match [regex]::Escape($inj.Original)) {
            Write-Host "         Original : " -NoNewline -ForegroundColor DarkGray
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "         Original : " -NoNewline -ForegroundColor DarkGray
            Write-Host "NAO ENCONTRADA" -ForegroundColor Red
            Write-Host "         Buscada  : '$($inj.Original)'" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "         -- Conteudo do membro (primeiras 40 linhas) --" -ForegroundColor Yellow
            $Linhas | Select-Object -First 40 | ForEach-Object {
                Write-Host "         | $_" -ForegroundColor White
            }
            Write-Host "         -- Fim do trecho --" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "         Copie a linha correta acima e atualize o campo" -ForegroundColor DarkGray
            Write-Host "         Original no injecoes.json para esta injecao." -ForegroundColor DarkGray
        }

        # --- Verifica string Injetada (nao deveria existir ainda) ---
        if ($Conteudo -match [regex]::Escape($inj.Injetado)) {
            Write-Host "         Injetado : " -NoNewline -ForegroundColor DarkGray
            Write-Host "JA PRESENTE no fonte (injecao pode ja estar aplicada)" -ForegroundColor Yellow
        }

        Remove-Item $TempFile -ErrorAction SilentlyContinue
    }

    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[EBOPS] Diagnostico concluido." -ForegroundColor DarkGray
    Write-Host "[EBOPS] Edite o injecoes.json com os valores exatos encontrados acima." -ForegroundColor DarkGray
    Write-Host ""
}

# ==============================================================================
# MOTOR DE INJECAO E REVERSAO
# ==============================================================================

function Validar-MembroPermitido {
    param([string]$Tipo, [string]$Membro)
    switch ($Tipo) {
        "COBOL" { if ($AllowedCOBOL -contains $Membro) { return $true } }
        "COPY"  { if ($AllowedCOPY  -contains $Membro) { return $true } }
        "JCL"   { if ($AllowedJCL   -contains $Membro) { return $true } }
    }
    return $false
}

function Obter-HLQ {
    param([string]$Tipo)
    switch ($Tipo) {
        "COBOL" { return $HLQ_COBOL }
        "COPY"  { return $HLQ_COPY  }
        "JCL"   { return $HLQ_JCL   }
    }
}

function Processar-Injecao {
    param([bool]$Reverter)

    $AcaoTexto = if ($Reverter) { "REVERSAO" } else { "INJECAO" }
    Write-Host "`n[EBOPS] --- $AcaoTexto DE DEMANDA ---" -ForegroundColor Yellow

    if (-not (Test-Path $ARQUIVO_INJECOES)) {
        Write-Host "[ERRO] injecoes.json nao encontrado: $ARQUIVO_INJECOES" -ForegroundColor Red; return
    }

    $Injecoes = Get-Content $ARQUIVO_INJECOES | ConvertFrom-Json
    $Estado   = Carregar-Estado

    Write-Host ""
    $Injecoes | ForEach-Object {
        $inj   = $_
        $Ativo = $Estado.injecoes_ativas | Where-Object { $_.Id -eq $inj.Id }
        if ($Ativo) {
            Write-Host "  [$($inj.Id)] $($inj.Titulo) [EM ANDAMENTO]" -ForegroundColor Yellow
        } else {
            Write-Host "  [$($inj.Id)] " -NoNewline -ForegroundColor Cyan
            Write-Host $inj.Titulo
        }
    }
    Write-Host ""

    $Escolha = Read-Host "[0] Cancelar ou digite o ID"
    if ($Escolha -eq "0") { return }

    $Injecao = $Injecoes | Where-Object { $_.Id -eq [int]$Escolha }
    if ($null -eq $Injecao) { Write-Host "[ERRO] Opcao invalida." -ForegroundColor Red; return }

    $JaAtiva = $Estado.injecoes_ativas | Where-Object { $_.Id -eq [int]$Escolha }

    if (-not $Reverter -and $JaAtiva) {
        Write-Host "[AVISO] Esta demanda ja esta em andamento desde $($JaAtiva.Timestamp)." -ForegroundColor Yellow
        Write-Host "[AVISO] Use a opcao Reversao (6) antes de reaplicar." -ForegroundColor Yellow
        return
    }
    if ($Reverter -and -not $JaAtiva) {
        Write-Host "[AVISO] Esta demanda nao esta registrada como ativa." -ForegroundColor Yellow; return
    }
    if (-not (Validar-MembroPermitido -Tipo $Injecao.TipoDataset -Membro $Injecao.Membro)) {
        Write-Host "[ERRO DE SEGURANCA] Membro nao esta na lista de modificacoes permitidas." -ForegroundColor Red; return
    }

    $HLQ_Alvo      = Obter-HLQ -Tipo $Injecao.TipoDataset
    $DatasetMembro = "$HLQ_Alvo($($Injecao.Membro))"
    $Busca         = if ($Reverter) { $Injecao.Injetado } else { $Injecao.Original }
    $Troca         = if ($Reverter) { $Injecao.Original } else { $Injecao.Injetado }

    Write-Host "[EBOPS] Processando demanda #$Escolha..." -ForegroundColor Magenta

    & zowe zos-files download data-set $DatasetMembro -f $ARQUIVO_LOCAL_TEMP 2>&1 | Out-Null

    if (-not (Test-Path $ARQUIVO_LOCAL_TEMP)) {
        Write-Host "[ERRO] Falha no download - verifique a conexao Zowe." -ForegroundColor Red; return
    }

    $Conteudo = Get-Content $ARQUIVO_LOCAL_TEMP -Raw

    if ($Conteudo -notmatch [regex]::Escape($Busca)) {
        $Contexto = if ($Reverter) { "injetada" } else { "original" }
        Write-Host ""
        Write-Host "  [AVISO] String $Contexto nao encontrada em $DatasetMembro." -ForegroundColor Yellow
        Write-Host "  Buscada: '$Busca'" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Use a opcao B para ver o conteudo real do membro e" -ForegroundColor DarkGray
        Write-Host "  corrigir o campo Original/Injetado no injecoes.json." -ForegroundColor DarkGray
        Write-Host ""
        Remove-Item $ARQUIVO_LOCAL_TEMP
        return
    }

    (Get-Content $ARQUIVO_LOCAL_TEMP) -replace [regex]::Escape($Busca), $Troca |
        Set-Content $ARQUIVO_LOCAL_TEMP

    & zowe zos-files upload file-to-data-set $ARQUIVO_LOCAL_TEMP $DatasetMembro 2>&1 | Out-Null
    Remove-Item $ARQUIVO_LOCAL_TEMP

    if (-not $Reverter) {
        $NovaEntrada = [PSCustomObject]@{
            Id = [int]$Escolha; Titulo = $Injecao.Titulo
            Membro = $Injecao.Membro; TipoDataset = $Injecao.TipoDataset
            Descricao = $Injecao.Descricao
            Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        }
        $Estado.injecoes_ativas = @($Estado.injecoes_ativas) + @($NovaEntrada)
        Salvar-Estado $Estado
        Write-Host "[EBOPS] Demanda aplicada com sucesso." -ForegroundColor Green
        Exibir-Ticket $Injecao
        if ($Injecao.TipoDataset -in @("COBOL", "COPY")) {
            Write-Host ""
            if ($Injecao.TipoDataset -eq "COPY") {
                Write-Host "  [!] Copybook modificado - todos os programas dependentes precisam ser recompilados." -ForegroundColor Yellow
            }
            $Compilar = Read-Host "[EBOPS] Deseja compilar agora? (EBDEPLOY) [S/N]"
            if ($Compilar -eq "S") { Executar-Job "EBDEPLOY" }
        }
    } else {
        $EntradaHist = [PSCustomObject]@{
            Id = [int]$Escolha; Titulo = $Injecao.Titulo
            Membro = $Injecao.Membro; TipoDataset = $Injecao.TipoDataset
            Descricao = $Injecao.Descricao
            RevertidoEm = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        }
        $Estado.historico       = @($Estado.historico) + @($EntradaHist)
        $Estado.injecoes_ativas = @($Estado.injecoes_ativas | Where-Object { $_.Id -ne [int]$Escolha })
        Salvar-Estado $Estado
        Write-Host "[EBOPS] Reversao concluida. Estado atualizado." -ForegroundColor Green
        if ($Injecao.TipoDataset -in @("COBOL", "COPY")) {
            Write-Host ""
            $Compilar = Read-Host "[EBOPS] Membro restaurado. Deseja recompilar agora? (EBDEPLOY) [S/N]"
            if ($Compilar -eq "S") { Executar-Job "EBDEPLOY" }
        }
    }
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

do {
    $EstadoAtual = Carregar-Estado
    $QtdAtivas   = if ($EstadoAtual.injecoes_ativas) { $EstadoAtual.injecoes_ativas.Count } else { 0 }
    $LabelAtivas = if ($QtdAtivas -gt 0) { " [$QtdAtivas EM ANDAMENTO]" } else { "" }

    Write-Host ""
    Write-Host "========================= EBOPS CLI ==========================" -ForegroundColor Cyan
    Write-Host "1. Reset (EBRESET)"
    Write-Host "2. Gerar Massa (Python)"
    Write-Host "3. Seed (Upload Lancamentos)"
    Write-Host "4. Backup (ELIEL.EMUNAH.**)"
    Write-Host "5. Aplicar Demanda"
    Write-Host "6. Reverter Demanda"
    Write-Host "7. Compilar (EBDEPLOY)"
    Write-Host "8. Rodar Cadeia (EBJCHAIN)"
    Write-Host "9. Set Status (EBSETSTS)"
    Write-Host "A. " -NoNewline
    if ($QtdAtivas -gt 0) {
        Write-Host "Status Admin$LabelAtivas" -ForegroundColor Yellow
    } else {
        Write-Host "Status Admin"
    }
    Write-Host "B. Diagnostico de Strings"
    Write-Host "0. Sair"

    $Opcao = Read-Host "Opcao"

    switch ($Opcao.ToUpper()) {
        "1" { Executar-Job "EBRESET" }
        "2" { Gerar-MassaLancamentos }
        "3" { Submeter-Seed }
        "4" { Realizar-Backup }
        "5" { Processar-Injecao -Reverter $false }
        "6" { Processar-Injecao -Reverter $true }
        "7" { Executar-Job "EBDEPLOY" }
        "8" { Executar-Job "EBJCHAIN" }
        "9" { Executar-Job "EBSETSTS" }
        "A" { Exibir-Status-Injecoes }
        "B" { Diagnosticar-Injecoes }
    }
} while ($Opcao -ne "0")
