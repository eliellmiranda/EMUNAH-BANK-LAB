# Cenario 00 — Build e Carga Inicial (Day Zero)

## Objetivo
Levar o laboratorio do zero ate o estado pronto para rodar a primeira execucao da cadeia batch. Cobre a sequencia completa: publicacao de fontes, alocacao de datasets, definicao de GDGs, build dos programas COBOL, carga inicial dos masters via seed.

Este cenario e a porta de entrada para todos os outros — `cenario-01` em diante assumem que este cenario foi concluido com sucesso.

## Pre-condicoes
- Conta no zXplore (Marist) ativa com HLQ proprio (ex.: `Z77948`)
- Zowe CLI instalado e perfil configurado (`zowe config init`)
- Repositorio clonado localmente
- VS Code com IBM Z Open Editor e Zowe Explorer instalados
- Conexao validada: `zowe zosmf check status` retorna `200 OK`

## Datasets envolvidos (estado final apos este cenario)

### Bibliotecas (com membros publicados)
- `<HLQ>.EMUNAH.DEV.COBOL` — fontes COBOL
- `<HLQ>.EMUNAH.DEV.COPY` — copybooks (layouts, telas, db2)
- `<HLQ>.EMUNAH.DEV.JCL` — JCLs de deploy, batch, util
- `<HLQ>.EMUNAH.DEV.LOADLIB` — modulos executaveis (gerados no build)
- `<HLQ>.EMUNAH.DEV.REXX` — scripts de automacao (opcional)

### VSAMs operacionais (populados pela carga seed)
- `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS` — 20 clientes
- `<HLQ>.EMUNAH.ARQ.CONTA.KSDS` — 40 contas (2 por cliente)
- `<HLQ>.EMUNAH.ARQ.LANCTO.ESDS` — vazio (sera populado no primeiro `EBJVALD`)

### Sequenciais (alocados vazios)
- `ARQ.ENTRADA.SEQ`, `ARQ.ENTRADA.TRAILER.SEQ`
- `ARQ.REJEITOS.SEQ`, `ARQ.AUDIT.SEQ`, `ARQ.CONCIL.SEQ`
- `ARQ.REPR.LANCTO.SEQ`, `ARQ.REPR.REJPERM.SEQ`
- `ARQ.CTL.STATUS`, `ARQ.CTL.PROCDATE` (vazios; serao escritos no primeiro `EBJSOD`)
- `STAGE.ENTRADA.SEQ` (alocado vazio; recebera o arquivo do dia via Zowe)

### Sequenciais seed (populados via upload Zowe)
- `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ` — 20 registros (LRECL=80)
- `<HLQ>.EMUNAH.SEED.CONTAS.SEQ` — 40 registros (LRECL=100)

### GDGs (bases definidas, sem geracoes)
- `ARQ.SALDO.GDG`, `ARQ.EXTRATO.GDG` (LIMIT=30)
- `ARQ.BKP.CLIENTE.GDG`, `ARQ.BKP.CONTA.GDG` (LIMIT=7)
- `ARQ.BKP.AUDIT.GDG`, `ARQ.BKP.REJEITOS.GDG` (LIMIT=14)

### Parametros
- `<HLQ>.EMUNAH.PARM.JUROS.CONFIG` (alocado em `EBALLOC`; preencher com taxas/datas)

## Sequencia de execucao

| Fase | Acao | Ferramenta | Resultado |
|------|------|------------|-----------|
| 1 | Upload de copybooks | Zowe CLI / Explorer | `DEV.COPY` populado |
| 2 | Upload de fontes COBOL | Zowe CLI / Explorer | `DEV.COBOL` populado |
| 3 | Upload de JCLs (deploy, batch, util) | Zowe CLI / Explorer | `DEV.JCL` populado |
| 4 | Submeter `EBALLOC` | Zowe submit | PDS, VSAMs e sequenciais alocados (RC=0) |
| 5 | Submeter `EBDEFGDG` | Zowe submit | 6 bases GDG definidas (RC=0) |
| 6 | Submeter `EBDEPLOY` | Zowe submit | 13 programas compilados em `DEV.LOADLIB` (RC<=4) |
| 7 | Upload dos seeds | Zowe CLI / Explorer | `SEED.CLIENTES.SEQ` e `SEED.CONTAS.SEQ` populados |
| 8 | Upload do `PARM.JUROS.CONFIG` | Zowe CLI / Explorer | parametros de juros gravados |
| 9 | Submeter `EBSEED` | Zowe submit | 20 clientes + 40 contas nos KSDS (RC=0) |
| 10 | Validar carga | `EBSALD01` ou `LISTCAT` | KSDS com registros, GDGs vazios |

## Como executar (Windows PowerShell + Zowe CLI)

### 1-3. Publicacao das bibliotecas
```powershell
# Copybooks
zowe files upload dir-to-pds copybooks/layouts "Z77948.EMUNAH.DEV.COPY" --recursive
zowe files upload dir-to-pds copybooks/telas   "Z77948.EMUNAH.DEV.COPY" --recursive
zowe files upload dir-to-pds copybooks/db2     "Z77948.EMUNAH.DEV.COPY" --recursive

# Fontes COBOL
zowe files upload dir-to-pds cobol/batch  "Z77948.EMUNAH.DEV.COBOL" --recursive
zowe files upload dir-to-pds cobol/util   "Z77948.EMUNAH.DEV.COBOL" --recursive
zowe files upload dir-to-pds cobol/common "Z77948.EMUNAH.DEV.COBOL" --recursive

# JCLs
zowe files upload dir-to-pds jcl/deploy  "Z77948.EMUNAH.DEV.JCL" --recursive
zowe files upload dir-to-pds jcl/batch   "Z77948.EMUNAH.DEV.JCL" --recursive
zowe files upload dir-to-pds jcl/util    "Z77948.EMUNAH.DEV.JCL" --recursive
zowe files upload dir-to-pds jcl/compile "Z77948.EMUNAH.DEV.JCL" --recursive
```

> Importante: Zowe nao preserva extensoes. Os arquivos viram membros (LRECL=80 truncado). Se algum membro ficar vazio, conferir o LRECL local antes do upload.

### 4-6. Alocacao + GDGs + build
```powershell
zowe jobs submit local-file "jcl/deploy/EBALLOC.jcl"   --wfo
zowe jobs submit local-file "jcl/deploy/EBDEFGDG.jcl"  --wfo
zowe jobs submit local-file "jcl/deploy/EBDEPLOY.jcl"  --wfo
```

> `EBDEPLOY` aborta em cascata (`COND=(4,LT)`) se qualquer compilacao retornar RC>=8. Investigar o primeiro step com falha antes de prosseguir.

### 7-8. Upload de seeds e parametros
```powershell
zowe files upload file-to-data-set `
  "data/seed/seed_clientes.txt" "Z77948.EMUNAH.SEED.CLIENTES.SEQ"

zowe files upload file-to-data-set `
  "data/seed/seed_contas.txt"   "Z77948.EMUNAH.SEED.CONTAS.SEQ"

zowe files upload file-to-data-set `
  "config/juros_config.txt"     "Z77948.EMUNAH.PARM.JUROS.CONFIG"
```

### 9. Carga inicial dos masters
```powershell
zowe jobs submit local-file "jcl/batch/EBSEED.jcl" --wfo
```

## Resultado esperado

| Verificacao | Comando / Job | Esperado |
|---|---|---|
| `EBALLOC` concluiu | spool | RC=0 em todos os 7 steps |
| `EBDEFGDG` concluiu | spool / `LISTCAT` | 6 GDGs com `LIMIT(n) NOEMPTY SCRATCH`, 0 geracoes |
| `EBDEPLOY` concluiu | spool | 13 modulos em `DEV.LOADLIB`, todos RC<=4 |
| Seeds populados | `LISTDS` | 20 reg em CLIENTES.SEQ, 40 em CONTAS.SEQ |
| `EBSEED` concluiu | spool | RC=0; 20 INSERTs em CLIENTE.KSDS; 40 em CONTA.KSDS |
| KSDS populados | `EBSALD01` ou `IDCAMS PRINT` | listagem dos 20 clientes / 40 contas |
| GDGs ainda vazios | `LISTCAT ENT('...GDG') ALL` | `ASSOCIATIONS--(NONE)` |
| `CTL.STATUS` vazio | `IEBGENER` ou ISPF BROWSE | sem conteudo (primeiro `EBJSOD` gravara `OPEN`) |

## Evidencias a coletar
- Spool de `EBALLOC`, `EBDEFGDG`, `EBDEPLOY`, `EBSEED`
- `LISTCAT ENT('Z77948.EMUNAH.ARQ.CLIENTE.KSDS') ALL` (mostra `HI-USED-RBA > 0`)
- Saida de `EBSALD01` exibindo os 20 clientes e 40 contas
- `LISTCAT` das 6 bases GDG (LIMIT correto, sem geracoes)
- Listagem da `DEV.LOADLIB` com os 13 modulos

## Erros comuns e resolucao

### `EBALLOC` falha com `IDC3009I` em algum DEFINE
Dataset ja existia. O `EBALLOC` faz `DELETE + SET MAXCC=0` antes de cada `DEFINE`, entao isso so ocorre se o `DELETE` tambem falhou (catalogo orfao). Resolver com `DELETE NOSCRATCH` manual e reexecutar.

### `EBDEPLOY` aborta em CL01 com erro de copybook nao encontrado
Os copybooks nao foram publicados antes do build. Voltar ao passo 1, reupload do `DEV.COPY`, reexecutar `EBDEPLOY`.

### `EBSEED` retorna RC=8 com "DUPLICATE KEY"
KSDS ja tem dados de uma execucao anterior. Para recomecar do zero, rodar `jcl/util/EBRESETF.jcl` e voltar ao passo 9. Para preservar os dados existentes, usar `EBJCLLD` (que aceita compartilhamento) em vez de `EBSEED`.

### `EBDEFGDG` retorna `IDC3007I LIMIT EXCEEDED`
Base GDG ja existia com geracoes. O `EBDEFGDG` faz `DELETE GDG FORCE`, entao isso indica catalogo inconsistente. `LISTCAT` para diagnosticar; se preciso, `EBRESETF` zera tudo.

### `EBSEED` grava no KSDS mas `EBSALD01` nao retorna nada
Possivel mismatch de chave. Verificar layout dos seeds (`CPCLI001` LRECL=80 com chave de 5 bytes; `CPCNT001` LRECL=100 com chave de 12 bytes). Conferir os primeiros bytes do seed conferem com a definicao do KSDS no `EBALLOC`.

## Proximo passo
Apos este cenario, o ambiente esta pronto para o **Cenario 01 — Cadeia Batch Normal**:

1. Subir o arquivo do dia para `STAGE.ENTRADA.SEQ` via Zowe.
2. Submeter a cadeia: `EBJPRECK -> EBJSOD -> EBJBCKPD -> EBJWAIT -> EBJLOAD -> EBJVALD -> EBJPOST -> EBJACCR -> EBJCUTF -> EBJSNAP -> EBJCUTE -> EBJCONC -> EBJEXTR -> EBJEOD`.

## Pontos de atencao
- O `PARM.JUROS.CONFIG` precisa de conteudo valido **antes** do primeiro `EBJACCR`. Se nao tiver dados, `EBACCR01` aborta. Pode ser populado depois deste cenario, mas e bom ja deixar pronto.
- O upload de seeds via Zowe CLI deve preservar os LRECL exatos (80 para clientes, 100 para contas). Usar `--encoding ISO8859-1` se houver caracteres acentuados.
- `EBDEPLOY` compila **e** link-edita em um unico job. Se quiser controlar separadamente (ex.: para inspecionar o listing antes do link), usar `EBCOMP` + `EBLINK` em sequencia.
- Este cenario nao define o `STAGE.ENTRADA.SEQ` — ele ja e alocado vazio pelo `EBALLOC` (step `ALOCSEQ`... ou em alguns redesenhos, alocado dinamicamente no primeiro upload). Verificar com `LISTCAT` apos o `EBALLOC`.

## Equivalencia com EBRESETF
Se voce ja rodou este cenario uma vez e quer voltar ao estado **antes** do passo 9 (sem refazer build/alocacao), use:

```powershell
zowe jobs submit local-file "jcl/util/EBRESETF.jcl" --wfo
zowe jobs submit local-file "jcl/batch/EBSEED.jcl"  --wfo
```

`EBRESETF` apaga masters/CTL/STAGE/GDGs e recria vazios. Detalhes em `docs/06-runbooks.md` ("Procedimento: reset de ambiente").
