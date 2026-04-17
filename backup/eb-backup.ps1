<#
.SYNOPSIS
    Backup completo do Emunah Bank Lab (PDS, sequenciais, VSAM, GDG).

.DESCRIPTION
    Orquestra o backup completo do laboratorio:
      1. Baixa todos os PDS de codigo e configuracao (DEV, HML, PRD).
      2. Baixa os arquivos sequenciais de negocio.
      3. Submete o JCL EBJBKUP para gerar flats dos VSAM no mainframe.
      4. Baixa os flats gerados pelo EBJBKUP.
      5. Baixa as N ultimas geracoes ativas do GDG ARQ.EXTRATO.
      6. Gera manifest.json, execution.log e info.txt.
      7. Retorna exit code diferente de zero se houver qualquer falha.

.PARAMETER Hlq
    High-Level Qualifier do mainframe. Default: Z77948.

.PARAMETER Project
    Qualifier do projeto. Default: EMUNAH.

.PARAMETER GdgGenerations
    Quantas geracoes do GDG baixar (da mais recente para a mais antiga). Default: 2.

.PARAMETER SkipVsam
    Se presente, pula a etapa de VSAM (nao submete EBJBKUP).

.PARAMETER OutputRoot
    Diretorio raiz onde a pasta de backup timestampada sera criada.
    Default: diretorio atual.

.EXAMPLE
    .\eb-backup.ps1
    Executa o backup com todos os defaults.

.EXAMPLE
    .\eb-backup.ps1 -Hlq Z77948 -GdgGenerations 3
    Executa o backup mantendo as 3 ultimas geracoes do GDG.

.NOTES
    Requer Zowe CLI v3.x configurado com perfil default ativo.
    Testar conexao antes: zowe zos-files list data-set "<HLQ>.EMUNAH.**"
#>

[CmdletBinding()]
param(
    [string]$Hlq = 'Z77948',
    [string]$Project = 'EMUNAH',
    [int]$GdgGenerations = 2,
    [switch]$SkipVsam,
    [string]$OutputRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# =========================================================
# CONFIGURACAO DERIVADA
# =========================================================
$Prefix = "$Hlq.$Project"

# PDS de codigo e configuracao
# Extensao define o sufixo aplicado aos membros baixados. Facilita syntax
# highlighting em editores locais e torna o repositorio git mais legivel.
# LOADLIB e binario - sem extensao.
$PdsList = @(
    @{ Name = "$Prefix.DEV.COBOL";   Ext = '.cbl'  }
    @{ Name = "$Prefix.DEV.COPY";    Ext = '.cpy'  }
    @{ Name = "$Prefix.DEV.JCL";     Ext = '.jcl'  }
    @{ Name = "$Prefix.DEV.REXX";    Ext = '.rexx' }
    @{ Name = "$Prefix.DEV.LOADLIB"; Ext = ''      }
    @{ Name = "$Prefix.HML.COBOL";   Ext = '.cbl'  }
    @{ Name = "$Prefix.HML.JCL";     Ext = '.jcl'  }
    @{ Name = "$Prefix.PRD.JCL";     Ext = '.jcl'  }
    @{ Name = "$Prefix.PRD.PARMLIB"; Ext = '.parm' }
)

# Arquivos sequenciais de negocio
$SeqList = @(
    "$Prefix.ARQ.ENTRADA.SEQ"
    "$Prefix.ARQ.REJEITO.SEQ"
    "$Prefix.ARQ.AUDIT.SEQ"
    "$Prefix.ARQ.CONCIL.SEQ"
    "$Prefix.SEED.CLIENTES.SEQ"
    "$Prefix.SEED.CONTAS.SEQ"
)

# VSAM: clusters origem e seus flats de backup correspondentes (gerados pelo EBJBKUP)
$VsamFlats = @(
    @{ Cluster = "$Prefix.ARQ.CLIENTE.KSDS"; Flat = "$Prefix.BKP.CLIENTE.FLAT"; OutFile = 'cliente.flat' }
    @{ Cluster = "$Prefix.ARQ.CONTA.KSDS";   Flat = "$Prefix.BKP.CONTA.FLAT";   OutFile = 'conta.flat'   }
    @{ Cluster = "$Prefix.ARQ.SALDO.KSDS";   Flat = "$Prefix.BKP.SALDO.FLAT";   OutFile = 'saldo.flat'   }
    @{ Cluster = "$Prefix.ARQ.LANCTO.ESDS";  Flat = "$Prefix.BKP.LANCTO.FLAT";  OutFile = 'lancto.flat'  }
)

$GdgBase = "$Prefix.ARQ.EXTRATO.GDG"
$JobDataSet = "$Prefix.DEV.JCL(EBJBKUP)"

# =========================================================
# ESTRUTURA DE DIRETORIOS
# =========================================================
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$BackupDir = Join-Path -Path $OutputRoot -ChildPath $Timestamp

$Dirs = [ordered]@{
    Root  = $BackupDir
    Pds   = Join-Path $BackupDir 'pds'
    Seq   = Join-Path $BackupDir 'arq\seq'
    Vsam  = Join-Path $BackupDir 'arq\vsam'
    Gdg   = Join-Path $BackupDir 'arq\gdg'
    Logs  = Join-Path $BackupDir 'logs'
}

foreach ($d in $Dirs.Values) {
    if (-not (Test-Path -LiteralPath $d)) {
        $null = New-Item -Path $d -ItemType Directory -Force
    }
}

$LogFile      = Join-Path $Dirs.Logs 'execution.log'
$ManifestFile = Join-Path $Dirs.Logs 'manifest.json'
$InfoFile     = Join-Path $Dirs.Logs 'info.txt'

# =========================================================
# CONTADORES E MANIFEST
# =========================================================
$Script:Manifest = @()
$Script:FailCount = 0
$Script:SuccessCount = 0
$Script:SkipCount = 0

# =========================================================
# FUNCOES AUXILIARES
# =========================================================
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'STEP')][string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    Add-Content -Path $LogFile -Value $line -Encoding UTF8

    switch ($Level) {
        'STEP'  { Write-Host ''; Write-Host $Message -ForegroundColor Cyan }
        'WARN'  { Write-Host "  $Message" -ForegroundColor Yellow }
        'ERROR' { Write-Host "  $Message" -ForegroundColor Red }
        default { Write-Host "  $Message" }
    }
}

function Add-ManifestEntry {
    param(
        [Parameter(Mandatory)][string]$Item,
        [Parameter(Mandatory)][ValidateSet('SUCCESS', 'FAIL', 'SKIP')][string]$Status,
        [string]$Detail = '',
        [string]$OutputPath = ''
    )

    $Script:Manifest += [PSCustomObject]@{
        item       = $Item
        status     = $Status
        detail     = $Detail
        outputPath = $OutputPath
        timestamp  = (Get-Date -Format 'o')
    }

    switch ($Status) {
        'SUCCESS' { $Script:SuccessCount++ }
        'FAIL'    { $Script:FailCount++ }
        'SKIP'    { $Script:SkipCount++ }
    }
}

function Invoke-Zowe {
    param(
        [Parameter(Mandatory)][string[]]$ZoweArgs,
        [switch]$Quiet
    )

    $output = & zowe @ZoweArgs 2>&1 | Out-String
    $exit = $LASTEXITCODE

    if (-not $Quiet) {
        Add-Content -Path $LogFile -Value "CMD: zowe $($ZoweArgs -join ' ')" -Encoding UTF8
        Add-Content -Path $LogFile -Value "EXIT: $exit" -Encoding UTF8
        Add-Content -Path $LogFile -Value "OUTPUT: $output" -Encoding UTF8
    }

    return [PSCustomObject]@{
        ExitCode = $exit
        Output   = $output
        Success  = ($exit -eq 0)
    }
}

function Copy-DataSetLocal {
    param(
        [Parameter(Mandatory)][string]$DataSetName,
        [Parameter(Mandatory)][string]$OutputPath,
        [switch]$Binary
    )

    $zoweArgs = @(
        'zos-files', 'download', 'data-set',
        $DataSetName,
        '--file', $OutputPath
    )
    if ($Binary) { $zoweArgs += '--binary' }

    $result = Invoke-Zowe -ZoweArgs $zoweArgs

    if ($result.Success) {
        Add-ManifestEntry -Item $DataSetName -Status 'SUCCESS' -OutputPath $OutputPath
        Write-Log "OK  $DataSetName" -Level INFO
    } else {
        Add-ManifestEntry -Item $DataSetName -Status 'FAIL' -Detail $result.Output
        Write-Log "FALHA $DataSetName (RC=$($result.ExitCode))" -Level ERROR
    }

    return $result.Success
}

function Copy-PdsLocal {
    param(
        [Parameter(Mandatory)][string]$PdsName,
        [Parameter(Mandatory)][string]$TargetDir,
        [string]$Extension = '',
        [switch]$Binary
    )

    Write-Log "PDS: $PdsName" -Level INFO

    $zoweArgs = @(
        'zos-files', 'download', 'all-members',
        $PdsName,
        '--directory', $TargetDir
    )
    if ($Binary) {
        $zoweArgs += '--binary'
    } elseif ($Extension) {
        # Flag nativo do Zowe. Baixa cada membro com a extensao aplicada
        # diretamente (EBPOST01 -> EBPOST01.cbl), sem etapa de rename local.
        $zoweArgs += @('--extension', $Extension)
    }

    $result = Invoke-Zowe -ZoweArgs $zoweArgs

    if ($result.Success) {
        $count = (Get-ChildItem -Path $TargetDir -File -ErrorAction SilentlyContinue | Measure-Object).Count
        $extLabel = if ($Extension) { " (ext: .$Extension)" } elseif ($Binary) { ' (binario)' } else { '' }
        Add-ManifestEntry -Item $PdsName -Status 'SUCCESS' `
            -Detail "membros baixados: $count$extLabel" `
            -OutputPath $TargetDir
        Write-Log "OK  $PdsName ($count membros$extLabel)" -Level INFO
    } else {
        Add-ManifestEntry -Item $PdsName -Status 'FAIL' -Detail $result.Output
        Write-Log "FALHA $PdsName (RC=$($result.ExitCode))" -Level ERROR
    }

    return $result.Success
}

function Submit-BackupJob {
    param(
        [Parameter(Mandatory)][string]$JobDataSet
    )

    Write-Log "Submetendo job: $JobDataSet" -Level INFO

    $zoweArgs = @(
        'jobs', 'submit', 'data-set',
        $JobDataSet,
        '--wait-for-output',
        '--rfj'
    )

    $result = Invoke-Zowe -ZoweArgs $zoweArgs

    if (-not $result.Success) {
        Write-Log "Submit falhou (RC=$($result.ExitCode))" -Level ERROR
        return $null
    }

    try {
        $jobJson = $result.Output | ConvertFrom-Json
        $jobId   = $jobJson.data.jobid
        $retcode = $jobJson.data.retcode

        Write-Log "Job submetido: JOBID=$jobId RETCODE=$retcode" -Level INFO

        return [PSCustomObject]@{
            JobId   = $jobId
            RetCode = $retcode
            Ok      = ($retcode -match '^CC 0000$' -or $retcode -match '^CC 0004$')
        }
    } catch {
        Write-Log "Falha ao parsear resposta do submit: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-GdgGenerations {
    param(
        [Parameter(Mandatory)][string]$GdgBase,
        [Parameter(Mandatory)][int]$Count
    )

    $result = Invoke-Zowe -ZoweArgs @(
        'zos-files', 'list', 'data-set',
        "$GdgBase.*",
        '--rfj'
    ) -Quiet

    if (-not $result.Success) {
        Write-Log "Nao foi possivel listar geracoes de $GdgBase" -Level WARN
        return @()
    }

    try {
        $json  = $result.Output | ConvertFrom-Json
        $items = @($json.data.apiResponse.items | ForEach-Object { $_.dsname })

        # Filtra apenas geracoes no formato G####V##
        $gens = $items | Where-Object { $_ -match '\.G\d{4}V\d{2}$' } |
                Sort-Object -Descending |
                Select-Object -First $Count

        return @($gens)
    } catch {
        Write-Log "Falha ao interpretar lista de GDG: $($_.Exception.Message)" -Level WARN
        return @()
    }
}

# =========================================================
# CABECALHO DE EXECUCAO
# =========================================================
"Timestamp........: $Timestamp"       | Set-Content -Path $InfoFile -Encoding UTF8
"HLQ..............: $Hlq"             | Add-Content -Path $InfoFile -Encoding UTF8
"Project..........: $Project"         | Add-Content -Path $InfoFile -Encoding UTF8
"Prefix...........: $Prefix"          | Add-Content -Path $InfoFile -Encoding UTF8
"Diretorio Backup.: $BackupDir"       | Add-Content -Path $InfoFile -Encoding UTF8
"GDG Generations..: $GdgGenerations"  | Add-Content -Path $InfoFile -Encoding UTF8
"SkipVsam.........: $SkipVsam"        | Add-Content -Path $InfoFile -Encoding UTF8

Write-Host ''
Write-Host '======================================================' -ForegroundColor Green
Write-Host '  EMUNAH LAB - BACKUP COMPLETO'                         -ForegroundColor Green
Write-Host "  Prefix....: $Prefix"
Write-Host "  Diretorio.: $BackupDir"
Write-Host "  GDG gens..: $GdgGenerations"
Write-Host "  SkipVsam..: $SkipVsam"
Write-Host '======================================================' -ForegroundColor Green

"Execucao iniciada em $(Get-Date -Format 'o')" | Set-Content -Path $LogFile -Encoding UTF8

# =========================================================
# PRE-FLIGHT: VERIFICACAO DO ZOWE CLI
# =========================================================
Write-Log '>>> PRE-FLIGHT: verificando Zowe CLI' -Level STEP

$zoweCheck = Invoke-Zowe -ZoweArgs @('--version') -Quiet
if (-not $zoweCheck.Success) {
    Write-Log 'Zowe CLI nao responde a --version. Verifique instalacao e PATH.' -Level ERROR
    exit 2
}
$zoweVersion = ($zoweCheck.Output -split "`n")[0].Trim()
Write-Log "Zowe CLI versao: $zoweVersion" -Level INFO

$profileCheck = Invoke-Zowe -ZoweArgs @('zos-files', 'list', 'data-set', "$Prefix.*", '--rfj') -Quiet
if (-not $profileCheck.Success) {
    Write-Log 'Zowe nao consegue listar datasets do lab. Verifique perfil e credenciais.' -Level ERROR
    Write-Log $profileCheck.Output -Level ERROR
    exit 3
}
Write-Log 'Zowe OK - perfil ativo e conexao com mainframe funcionando.' -Level INFO

# =========================================================
# BLOCO 1 - PDS (CODIGO E CONFIGURACAO)
# =========================================================
Write-Log '>>> BLOCO 1: PDS (CODIGO E CONFIGURACAO)' -Level STEP

foreach ($pds in $PdsList) {
    $name      = $pds.Name
    $ext       = $pds.Ext
    $folderName = ($name -replace '\.', '_')
    $target    = Join-Path $Dirs.Pds $folderName
    if (-not (Test-Path $target)) { $null = New-Item -Path $target -ItemType Directory -Force }

    # LOADLIB eh binario (Ext vazio)
    $isBinary = [string]::IsNullOrEmpty($ext)

    # Remove o ponto inicial: Zowe espera 'cbl', nao '.cbl'
    $extForZowe = if ($ext) { $ext.TrimStart('.') } else { '' }

    [void](Copy-PdsLocal -PdsName $name -TargetDir $target -Extension $extForZowe -Binary:$isBinary)
}

# =========================================================
# BLOCO 2 - ARQUIVOS SEQUENCIAIS
# =========================================================
Write-Log '>>> BLOCO 2: ARQUIVOS SEQUENCIAIS' -Level STEP

foreach ($ds in $SeqList) {
    $fileName = ($ds -replace "^$([regex]::Escape($Prefix))\.", '').Replace('.', '_') + '.txt'
    $outPath = Join-Path $Dirs.Seq $fileName
    [void](Copy-DataSetLocal -DataSetName $ds -OutputPath $outPath)
}

# =========================================================
# BLOCO 3 - VSAM (VIA EBJBKUP)
# =========================================================
if ($SkipVsam) {
    Write-Log '>>> BLOCO 3: VSAM - IGNORADO (-SkipVsam)' -Level STEP
    foreach ($v in $VsamFlats) {
        Add-ManifestEntry -Item $v.Cluster -Status 'SKIP' -Detail '-SkipVsam ativo'
    }
} else {
    Write-Log '>>> BLOCO 3: VSAM (VIA EBJBKUP)' -Level STEP

    $jobResult = Submit-BackupJob -JobDataSet $JobDataSet

    if ($null -eq $jobResult) {
        Write-Log 'EBJBKUP: submit falhou. Flats nao serao baixados.' -Level ERROR
        foreach ($v in $VsamFlats) {
            Add-ManifestEntry -Item $v.Flat -Status 'FAIL' -Detail 'Submit do EBJBKUP falhou'
        }
    } elseif (-not $jobResult.Ok) {
        Write-Log "EBJBKUP terminou com RC ruim: $($jobResult.RetCode). Flats nao serao baixados." -Level ERROR
        foreach ($v in $VsamFlats) {
            Add-ManifestEntry -Item $v.Flat -Status 'FAIL' -Detail "EBJBKUP RC=$($jobResult.RetCode)"
        }
    } else {
        Write-Log "EBJBKUP OK (JOBID=$($jobResult.JobId) RC=$($jobResult.RetCode)). Baixando flats." -Level INFO
        foreach ($v in $VsamFlats) {
            $outPath = Join-Path $Dirs.Vsam $v.OutFile
            [void](Copy-DataSetLocal -DataSetName $v.Flat -OutputPath $outPath)
        }
    }
}

# =========================================================
# BLOCO 4 - GDG (ARQ.EXTRATO)
# =========================================================
Write-Log '>>> BLOCO 4: GDG (ARQ.EXTRATO)' -Level STEP

$gens = Get-GdgGenerations -GdgBase $GdgBase -Count $GdgGenerations

if ($gens.Count -eq 0) {
    Write-Log "Nenhuma geracao encontrada para $GdgBase" -Level WARN
    Add-ManifestEntry -Item $GdgBase -Status 'SKIP' -Detail 'nenhuma geracao ativa'
} else {
    Write-Log "Geracoes selecionadas ($($gens.Count)): $($gens -join ', ')" -Level INFO
    foreach ($g in $gens) {
        $suffix  = ($g -replace '.*\.(G\d{4}V\d{2})$', '$1').ToLower()
        $outPath = Join-Path $Dirs.Gdg "extrato_$suffix.txt"
        [void](Copy-DataSetLocal -DataSetName $g -OutputPath $outPath)
    }
}

# =========================================================
# MANIFEST E RESUMO FINAL
# =========================================================
$Script:Manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $ManifestFile -Encoding UTF8

$total = $Script:SuccessCount + $Script:FailCount + $Script:SkipCount

Write-Host ''
Write-Host '======================================================' -ForegroundColor Green
Write-Host '  BACKUP FINALIZADO'                                    -ForegroundColor Green
Write-Host "  Diretorio..: $BackupDir"
Write-Host "  Sucessos...: $Script:SuccessCount / $total"
Write-Host "  Falhas.....: $Script:FailCount"
Write-Host "  Ignorados..: $Script:SkipCount"
Write-Host "  Manifest...: $ManifestFile"
Write-Host "  Log........: $LogFile"
Write-Host '======================================================' -ForegroundColor Green

Add-Content -Path $LogFile -Value "Execucao finalizada em $(Get-Date -Format 'o')" -Encoding UTF8
Add-Content -Path $LogFile -Value "Sucessos: $Script:SuccessCount | Falhas: $Script:FailCount | Ignorados: $Script:SkipCount" -Encoding UTF8

if ($Script:FailCount -gt 0) {
    Write-Host ''
    Write-Host "Backup concluido com $Script:FailCount falha(s). Verifique $ManifestFile" -ForegroundColor Red
    exit 1
}

exit 0
