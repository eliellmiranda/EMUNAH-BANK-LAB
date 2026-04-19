# Backup do Emunah Bank Lab

Utilitário de backup completo do laboratório mainframe Emunah. Baixa para a máquina local, de forma automatizada, todo o conteúdo relevante do lab no mainframe: código fonte, JCL, arquivos sequenciais, VSAM e gerações do GDG.

---

## O que o backup cobre

| Categoria | Datasets |
|---|---|
| Código fonte | `DEV.COBOL`, `DEV.COPY`, `HML.COBOL` |
| JCL | `DEV.JCL`, `HML.JCL`, `PRD.JCL` |
| Scripts e config | `DEV.REXX`, `PRD.PARMLIB` |
| Executáveis | `DEV.LOADLIB` (binário) |
| Arquivos de negócio | `ARQ.ENTRADA.SEQ`, `ARQ.REJEITO.SEQ`, `ARQ.AUDIT.SEQ`, `ARQ.CONCIL.SEQ` |
| Seeds | `SEED.CLIENTES.SEQ`, `SEED.CONTAS.SEQ` |
| VSAM | `ARQ.CLIENTE.KSDS`, `ARQ.CONTA.KSDS`, `ARQ.SALDO.KSDS`, `ARQ.LANCTO.ESDS` (via REPRO) |
| GDG | `ARQ.EXTRATO.GDG` (N últimas gerações) |

Todos prefixados por `<HLQ>.EMUNAH` (default `<HLQ>.EMUNAH`).

---

## Componentes

O backup é composto por dois artefatos que trabalham em conjunto:

### EBJBKUP.jcl — job de backup VSAM

Fica armazenado no mainframe em `<HLQ>.EMUNAH.DEV.JCL(EBJBKUP)`. Executa IDCAMS REPRO dos 4 clusters VSAM do lab para arquivos sequenciais flat em `<HLQ>.EMUNAH.BKP.*.FLAT`. Grava registro de auditoria em `ARQ.AUDIT.SEQ`. É o único caminho viável para backup de VSAM, já que o protocolo zOSMF REST não permite download direto de clusters.

### eb-backup.ps1 — orquestrador local

Roda na workstation. Responsável por baixar os PDS e sequenciais diretamente, submeter o EBJBKUP e baixar os flats gerados, listar as gerações do GDG e baixar as N últimas, e gerar logs, manifest e exit code representativo do resultado.

---

## Pré-requisitos

| Requisito | Como validar |
|---|---|
| Zowe CLI v3.x instalado | `zowe --version` |
| Perfil Zowe ativo com credenciais zOSMF | `zowe config list` |
| PowerShell 5.1 ou superior | `$PSVersionTable.PSVersion` |
| JCL `EBJBKUP` instalado no mainframe | `zowe zos-files list all-members "<HLQ>.EMUNAH.DEV.JCL"` |
| Execução de scripts liberada | `Get-ExecutionPolicy -Scope CurrentUser` |

---

## Instalação

Fluxo único na primeira vez:

```powershell
# 1. Libera execução de scripts PowerShell para o usuário atual
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 2. Desbloqueia o script (remove flag "origem internet")
Unblock-File -Path .\eb-backup.ps1

# 3. Sobe o JCL EBJBKUP para o mainframe
zowe zos-files upload file-to-data-set ".\EBJBKUP.jcl" "<HLQ>.EMUNAH.DEV.JCL(EBJBKUP)"

# 4. Valida o JCL executando uma vez manualmente
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBJBKUP)" --wait-for-output
```

O passo 4 deve retornar `CC 0000`. Se retornar qualquer outro código, diagnosticar o EBJBKUP antes de continuar.

---

## Uso

### Execução padrão

```powershell
.\eb-backup.ps1
```

Usa os defaults: HLQ `<HLQ>`, projeto `EMUNAH`, 2 gerações do GDG, backup VSAM habilitado.

### Execução com parâmetros

```powershell
.\eb-backup.ps1 -Hlq <HLQ> -Project EMUNAH -GdgGenerations 3
```

### Backup rápido (sem VSAM)

Útil quando você só precisa salvar fontes e configuração, sem esperar o job batch:

```powershell
.\eb-backup.ps1 -SkipVsam
```

### Parâmetros disponíveis

| Parâmetro | Default | Descrição |
|---|---|---|
| `-Hlq` | `<HLQ>` | High-Level Qualifier do mainframe |
| `-Project` | `EMUNAH` | Qualifier do projeto |
| `-GdgGenerations` | `2` | Quantas gerações do GDG baixar, da mais recente para a mais antiga |
| `-SkipVsam` | `false` | Se presente, não submete o EBJBKUP e pula os flats VSAM |
| `-OutputRoot` | diretório atual | Pasta onde o subdiretório timestampado será criado |

---

## Estrutura de saída

Cada execução cria uma pasta timestampada:

```
20260417_184743/
├── pds/
│   ├── <HLQ>_EMUNAH_DEV_COBOL/     (membros como .cbl)
│   ├── <HLQ>_EMUNAH_DEV_COPY/      (membros como .cpy)
│   ├── <HLQ>_EMUNAH_DEV_JCL/       (membros como .jcl)
│   ├── <HLQ>_EMUNAH_DEV_REXX/      (membros como .rexx)
│   ├── <HLQ>_EMUNAH_DEV_LOADLIB/   (binário, sem extensão)
│   ├── <HLQ>_EMUNAH_HML_COBOL/     (membros como .cbl)
│   ├── <HLQ>_EMUNAH_HML_JCL/       (membros como .jcl)
│   ├── <HLQ>_EMUNAH_PRD_JCL/       (membros como .jcl)
│   └── <HLQ>_EMUNAH_PRD_PARMLIB/   (membros como .parm)
├── arq/
│   ├── seq/
│   │   ├── ARQ_ENTRADA_SEQ.txt
│   │   ├── ARQ_REJEITO_SEQ.txt
│   │   ├── ARQ_AUDIT_SEQ.txt
│   │   ├── ARQ_CONCIL_SEQ.txt
│   │   ├── SEED_CLIENTES_SEQ.txt
│   │   └── SEED_CONTAS_SEQ.txt
│   ├── vsam/
│   │   ├── cliente.flat
│   │   ├── conta.flat
│   │   ├── saldo.flat
│   │   └── lancto.flat
│   └── gdg/
│       ├── extrato_g0001v00.txt
│       └── extrato_g0002v00.txt
└── logs/
    ├── info.txt
    ├── execution.log
    └── manifest.json
```

### Extensões aplicadas aos membros de PDS

Membros de PDS no mainframe não têm extensão nativa (`EBPOST01`, `CPCLI001`, etc.). O script aplica extensões no download usando o flag `--extension` do Zowe CLI, o que facilita syntax highlighting em editores locais e torna o repositório git mais legível.

| PDS | Extensão aplicada |
|---|---|
| `DEV.COBOL`, `HML.COBOL` | `.cbl` |
| `DEV.COPY` | `.cpy` |
| `DEV.JCL`, `HML.JCL`, `PRD.JCL` | `.jcl` |
| `DEV.REXX` | `.rexx` |
| `PRD.PARMLIB` | `.parm` |
| `DEV.LOADLIB` | sem extensão (binário) |

Arquivos sequenciais mantêm extensão `.txt` genérica, independente do conteúdo.

---

## Arquivos de log

### info.txt

Metadados estáticos da execução: timestamp, HLQ, projeto, parâmetros.

### execution.log

Linha a linha, todos os comandos Zowe executados, com exit code e stdout/stderr completo. Primeira coisa a consultar quando algo falha.

### manifest.json

Lista estruturada de cada item tentado, com status `SUCCESS`, `FAIL` ou `SKIP`. Cada entrada contém:

```json
{
  "item": "<HLQ>.EMUNAH.DEV.COBOL",
  "status": "SUCCESS",
  "detail": "membros baixados: 7",
  "outputPath": "C:\\...\\pds\\<HLQ>_EMUNAH_DEV_COBOL",
  "timestamp": "2026-04-17T19:03:59-03:00"
}
```

Para auditoria e pós-mortem, o manifest é a fonte autoritativa.

---

## Exit codes

| Código | Significado | Ação |
|---|---|---|
| `0` | Backup completo sem falhas | Nenhuma |
| `1` | Backup concluído com falhas parciais | Ler `manifest.json` e identificar itens FAIL |
| `2` | Zowe CLI não responde | Validar instalação: `zowe --version` |
| `3` | Perfil Zowe não acessa o mainframe | Validar perfil: `zowe config list` e credenciais |

Diferente do script antigo, que terminava sempre com `0`, aqui o exit code reflete o resultado real. Isso permite encadeamento em pipelines e schedulers.

---

## Checklist de validação pós-backup

Após cada execução, validar nesta ordem:

1. **Exit code:** `echo $LASTEXITCODE` retornou `0`
2. **Manifest:** nenhum item com `"status": "FAIL"`
3. **Contagem de PDS:** cada pasta em `pds/` tem arquivos
4. **Flats VSAM existem no mainframe:** `zowe zos-files list data-set "<HLQ>.EMUNAH.BKP.*" --attributes`
5. **Flats VSAM baixados localmente:** 4 arquivos em `arq/vsam/` com tamanho maior que zero
6. **GDG baixado:** N arquivos em `arq/gdg/` (conforme `-GdgGenerations`)
7. **Spool do EBJBKUP:** `zowe jobs list jobs --owner <HLQ>` — último job com CC 0000
8. **Auditoria gravada:** `arq/seq/ARQ_AUDIT_SEQ.txt` contém linha `EBJBKUP CONCLUIDO`

---

## Troubleshooting

### Erro: "Unknown argument: mr"

Versão do Zowe CLI incompatível com o flag. Verificar se está usando a versão atual do `eb-backup.ps1` (sem `--mr wait`).

### Erro: "O arquivo não está assinado digitalmente"

Política de execução do PowerShell bloqueou o script:
```powershell
Unblock-File -Path .\eb-backup.ps1
```

### Submit do EBJBKUP falhou

Verificar se o JCL está no mainframe:
```powershell
zowe zos-files list all-members "<HLQ>.EMUNAH.DEV.JCL" | findstr EBJBKUP
```

Se não aparecer, executar o passo 3 da seção Instalação.

### EBJBKUP retorna RC 12 no STEP010

Primeira execução após criar os VSAM: o DELETE tenta apagar datasets que ainda não existem. O `SET MAXCC = 0` dentro do SYSIN força RC=0. Se o erro persistir, o problema é outro — verificar spool do job.

### EBJBKUP retorna RC 4 ou 12 em STEPs 020-050

Algum VSAM origem está vazio, corrompido ou com problema de catálogo. Verificar com:
```
LISTCAT ENT(<HLQ>.EMUNAH.ARQ.<NOME>.KSDS) ALL
```

### Exit code 3 no pre-flight

Perfil Zowe sem acesso. Reconfigurar:
```powershell
zowe config auto-init --prompt
```

### Flats VSAM existem no mainframe mas download falhou

Provavelmente problema temporário de conexão. Rodar novamente com `-SkipVsam` e depois baixar manualmente:
```powershell
zowe zos-files download data-set "<HLQ>.EMUNAH.BKP.CLIENTE.FLAT" --file ".\cliente.flat"
```

---

## Restauração

O backup atual é unidirecional: baixa do mainframe para local. Restauração é manual e depende do tipo de artefato.

### PDS (código e JCL)

Subir o conteúdo local de volta ao mainframe:

```powershell
zowe zos-files upload dir-to-uss ".\pds\<HLQ>_EMUNAH_DEV_COBOL" "/tmp/restore"
# depois mover ao PDS via JCL IEBCOPY
```

Método simples membro a membro:

```powershell
zowe zos-files upload file-to-data-set ".\pds\<HLQ>_EMUNAH_DEV_COBOL\EBPOST01.cbl" "<HLQ>.EMUNAH.DEV.COBOL(EBPOST01)"
```

### Arquivos sequenciais

```powershell
zowe zos-files upload file-to-data-set ".\arq\seq\ARQ_ENTRADA_SEQ.txt" "<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ"
```

### VSAM

Restauração de VSAM exige JCL de REPRO inverso (sequencial flat → cluster). Esse JCL ainda não existe no lab e está no backlog como `EBJREST` (contraparte do `EBJBKUP`). Até lá, restauração de VSAM é operação manual documentada caso a caso.

---

## Periodicidade recomendada

| Evento | Ação |
|---|---|
| Antes de qualquer alteração estrutural (criar/deletar dataset) | Backup completo |
| Antes de rodar nova cadeia batch completa | Backup completo |
| Após conclusão de fase do roadmap | Backup completo + commit no git |
| Diário durante desenvolvimento ativo | `-SkipVsam` (mais rápido) |
| Antes de desinstalar ou migrar ambiente zXplore | Backup completo + validação de todos os flats |

---

## Limitações conhecidas

- Restauração não é automatizada (apenas backup)
- Datasets migrados pelo HSM não são tratados explicitamente (o Zowe usa default silencioso)
- O script não detecta datasets novos que não estão na lista fixa — datasets criados ad-hoc fora do modelo funcional ficam de fora
- Não há verificação de integridade dos flats (comparação de contagem de registros entre origem e destino)
- GDG é listado via wildcard, o que pode retornar até 1000 itens e truncar em bases muito extensas

Itens documentados no backlog para evolução futura.

---

## Convenções utilizadas

- Prefixo `EB` em programas e jobs, conforme convenção do Emunah Lab
- `EBJBKUP` segue padrão `EBJ*` para jobs
- Datasets de backup em `<HLQ>.EMUNAH.BKP.<NOME>.FLAT`
- DDNAMEs no JCL usam 6-8 caracteres descritivos (`CLIEIN`, `CLIEOUT`, etc.)
- Comentários em cada step do JCL seguem o padrão de cabeçalho estabelecido nos jobs existentes
- Script PowerShell usa verbos aprovados (`Copy-`, `Submit-`, `Get-`, `Add-`, `Write-`)
