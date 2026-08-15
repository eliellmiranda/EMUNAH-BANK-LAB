# Emunah Bank Lab — Roadmap de Desenvolvimento
## Fases 3.5 · 3.6 · 4 · 5 · 6

**Autor:** Eliel  
**Data de criação:** 2026-08-13  
**Branch:** `refactor/cadeia-batch-ver-04`  
**Status:** Em andamento

---

## Sumário

| Fase | Escopo | Status |
|---|---|---|
| 3.5 | ESLD end-to-end: APCT abend — DB2CONN + CSSL log | Em andamento |
| 3.6 | EBCSTRF: MQPUT em 4000-CONFIRMAR-TRANSFERENCIA | Pendente |
| 4 | REXX: SDSF API (EBSDSF) + RXSQL operador (EBRXSQL) | Pendente |
| 5 | EBOPS USS: API REST Node.js em z/OS USS | Pendente |
| 6 | HLASM: EBASMSUM + EBCOREDP (continuação) | Pendente |

---

## Fase 3.5 — ESLD end-to-end test: APCT abend

### Estado atual

Todos os artefatos CICS estão instalados no CSD grupo `EMUNAH`:

| Recurso CSD | Status |
|---|---|
| `PROGRAM(EBCSSLD)` Language=CObol | Instalado |
| `MAPSET(MSBSLD)` | Instalado |
| `TRANSACTION(ESLD)` Program=EBCSSLD | Instalado |
| `LIBRARY(EMUNAH)` DSNAME01=ELIEL.EMUNAH.ONLINE.LOADLIB | Instalado |

DB2: `PLAN(EBCSSLD)` OPERATIVE=Y, `GRANT EXECUTE TO PUBLIC` feito.

Build `EBCSSLDJ`: PRECOMP=4(warn), CICSTRAN=0, COMPILE=0, LKED=0, BIND=0.

### Problema em aberto: APCT antes do primeiro EXEC CICS

APCT disparado antes de qualquer `EXEC CICS` executar. CEDF confirma que o EIB
é preenchido (tarefa iniciada), mas o abend ocorre na inicialização do stub DB2.

**Causa provável:** `DB2CONN(DBD1)` não definido ou não instalado no CSD. Sem
esse recurso, o CICS não consegue estabelecer a interface com o DB2 (DSNCSQL) e
aborta a tarefa com APCT no momento em que tenta criar a thread.

### Ações necessárias (em ordem)

1. **CEBR CSSL** — ler a fila transiente CSSL procurando mensagens `DSNC*`.
   - `DSNC1020` = conexão DB2 inativa
   - `DSNC1022` = subsistema DB2 não encontrado
   - `DSNC2005` = criação de thread falhou

2. **CEDA DISPLAY DB2CONN(DBD1)** — confirmar se o recurso existe no CSD.

3. Se ausente, definir e instalar:
   ```
   CEDA DEFINE DB2CONN(DBD1)
        GROUP(EMUNAH)
        DB2ID(DBD1)
        ACCOUNTREC(TASK)
        AUTHTYPE(USERID)
        MESSAGELEN(80)
        NONTERMREL(NORMAL)
   CEDA INSTALL DB2CONN(DBD1) GROUP(EMUNAH)
   ```

4. **CEMT INQUIRE DB2CONN** — confirmar `CONNECTED AVAILABLE`.

5. Retestar `ESLD` com agência `0001` conta `00000001`.

### Melhoria planejada: log CSSL estruturado (Step 3.5 — EBCSSLD)

O código atual em `2500-CONSULTAR-SALDO-DB2` escreve apenas 4 bytes binários
(`WS-SQLCODE-ED PIC S9(9) COMP`) no CSSL via `WRITEQ TD`. Isso é ilegível no
`CEBR`.

A melhoria substitui por uma mensagem estruturada de 55 bytes no formato:

```
TRNID(4) TASKN(7) SQLCODE:(+9) EBCSSLD DB2 ERROR
```

Exemplo visível no CEBR:
```
ESLD 0001234 SQLCODE:-0000204 EBCSSLD DB2 ERROR
```

Campos planejados na WORKING-STORAGE (`WS-CSSL-LOG`, 55 bytes):

| Campo | PIC | Bytes | Conteúdo |
|---|---|---|---|
| `WS-CSSL-TRNID` | X(4) | 4 | `EIBTRNID` |
| FILLER | X(1) | 1 | espaço |
| `WS-CSSL-TASKN` | 9(7) | 7 | `EIBTASKN` |
| FILLER | X(1) | 1 | espaço |
| `WS-CSSL-LABEL` | X(8) | 8 | literal `SQLCODE:` |
| `WS-CSSL-SQLCODE` | +9(9) | 10 | SQLCODE editado com sinal |
| FILLER | X(1) | 1 | espaço |
| `WS-CSSL-PGMID` | X(8) | 8 | literal `EBCSSLD ` |
| `WS-CSSL-SUFIXO` | X(16) | 16 | literal `DB2 ERROR      ` |

**Nota de arquivo:** o arquivo de desenvolvimento canônico é
`ELIEL.EMUNAH/ELIEL/EMUNAH/DEV/COBOL/EBCSSLD.cbl` (contém DB2).
O arquivo `cobol/online/EBCSSLD.cbl` é uma versão anterior sem DB2 —
deve ser atualizado em conjunto.

### Nota: merge conflict EBCSSLDJ.jcl

O arquivo `jcl/compile/EBCSSLDJ.jcl` está marcado `UU` no git mas o conteúdo
no disco já está correto (PRECOMP → CICSTRAN → COMPILE — ordem IBM documentada).
Ação necessária antes do próximo push: `git add jcl/compile/EBCSSLDJ.jcl`.

---

## Fase 3.6 — MQPUT em EBCSTRF (4000-CONFIRMAR-TRANSFERENCIA)

### Objetivo

Após a transferência ser efetivada com sucesso (ambos os REWRITE concluídos),
o parágrafo `4000-CONFIRMAR-TRANSFERENCIA` deve publicar um evento no MQ antes
de enviar o mapa de confirmação ao terminal. Esse evento simula a integração
event-driven que bancos reais usam para notificar sistemas downstream
(contabilidade, cobrança, notificações ao cliente, auditoria em tempo real).

### Design da mensagem MQ

**Queue manager:** `CSQ9MSTR` (EBSHTDWN.rexx confirma o nome do QMgr)  
**Queue de destino:** `EMUNAH.TRF.EVENTOS` (a definir via CSQUTIL)  
**Tamanho da mensagem:** 80 bytes (PIC X(80))

Formato da mensagem:

```
Pos 01-04  TRNID      PIC X(4)    'ETRF'
Pos 05-05  FILLER     PIC X(1)    ' '
Pos 06-12  TASKNUM    PIC 9(7)    EIBTASKN
Pos 13-13  FILLER     PIC X(1)    ' '
Pos 14-17  AGENCIA    PIC 9(4)    WS-AG-ORIG
Pos 18-25  CONTA-O    PIC 9(8)    WS-CT-ORIG
Pos 26-26  FILLER     PIC X(1)    ' '
Pos 27-30  AGENCIA-D  PIC 9(4)    WS-AG-DEST
Pos 31-38  CONTA-D    PIC 9(8)    WS-CT-DEST
Pos 39-39  FILLER     PIC X(1)    ' '
Pos 40-52  VALOR      S9(11)V99   WS-VALOR-TRF editado
Pos 53-80  FILLER     X(28)       espaços
```

### Blocos COBOL planejados

Na WORKING-STORAGE:
```cobol
*---------------------------------------------------------------*
* Area de mensagem MQ para evento de transferencia             *
* 80 bytes — publicado em EMUNAH.TRF.EVENTOS apos REWRITE OK   *
*---------------------------------------------------------------*
 01  WS-MQ-MSG.
     05 WS-MQ-TRNID             PIC X(4).
     05 FILLER                  PIC X(1) VALUE ' '.
     05 WS-MQ-TASKN             PIC 9(7).
     05 FILLER                  PIC X(1) VALUE ' '.
     05 WS-MQ-AG-ORIG           PIC 9(4).
     05 WS-MQ-CT-ORIG           PIC 9(8).
     05 FILLER                  PIC X(1) VALUE ' '.
     05 WS-MQ-AG-DEST           PIC 9(4).
     05 WS-MQ-CT-DEST           PIC 9(8).
     05 FILLER                  PIC X(1) VALUE ' '.
     05 WS-MQ-VALOR             PIC ZZZ.ZZZ.ZZ9,99.
     05 FILLER                  PIC X(28) VALUE SPACES.
 01  WS-MQ-MSG-LEN              PIC S9(8) COMP VALUE 80.
 01  WS-MQ-RESP                 PIC S9(8) COMP.
```

No parágrafo `4000-CONFIRMAR-TRANSFERENCIA`, antes do EXEC CICS SEND MAP:
```cobol
*-- Monta evento MQ de transferencia ------------------------*
     MOVE EIBTRNID              TO WS-MQ-TRNID
     MOVE EIBTASKN              TO WS-MQ-TASKN
     MOVE WS-AG-ORIG            TO WS-MQ-AG-ORIG
     MOVE WS-CT-ORIG            TO WS-MQ-CT-ORIG
     MOVE WS-AG-DEST            TO WS-MQ-AG-DEST
     MOVE WS-CT-DEST            TO WS-MQ-CT-DEST
     MOVE WS-VALOR-EDIT         TO WS-MQ-VALOR

*-- Publica no MQ (PUTQ nao conversacional) -----------------*
     EXEC CICS WRITEQ TD
         QUEUE('EMTF')
         FROM(WS-MQ-MSG)
         LENGTH(WS-MQ-MSG-LEN)
         RESP(WS-MQ-RESP)
     END-EXEC
```

**Decisão de implementação:** usar `EXEC CICS WRITEQ TD` apontando para uma
fila `EMTF` definida como INTRA (TD INDIRECTQ → EMUNAH.TRF.EVENTOS) em vez de
`EXEC CICS PUT CONTAINER` ou `MQPUT` direto, por ser a API mais simples
disponível no laboratório sem exigir `MQCONN` separado. Isso é suficiente para
demonstrar o padrão event-driven. Uma nota no código indica que em produção
seria `MQPUT` via CSQCICS ou ECI.

**Pré-requisito:** definir a TD ENTRY `EMTF` no CSD:
```
CEDA DEFINE TDQUEUE(EMTF)
     GROUP(EMUNAH)
     TYPE(INTRA)
     RECOVSTATUS(NO)
     TRIGSENDCOUNT(0)
```

---

## Fase 4 — REXX: SDSF API + RXSQL Operador

### 4.1 EBSDSF.rexx — leitura de status de jobs via SDSF REXX API

**Localização:** `rexx/operador/EBSDSF.rexx`

**Objetivo:** permitir que o operador consulte o status de jobs da cadeia batch
diretamente do TSO/ISPF sem abrir o painel SDSF. A API REXX do SDSF
(`ISFEXEC`) expõe as filas ST, DA, O, JDS — o script navega pela ST (fila de
jobs encerrados e ativos).

**Interface:**
```
EX 'HLQ.DEV.REXX(EBSDSF)'
EX 'HLQ.DEV.REXX(EBSDSF)' 'EBJCHAIN'      <- filtra por jobname
EX 'HLQ.DEV.REXX(EBSDSF)' 'EBJCHAIN LAST' <- apenas o mais recente
```

**Saída esperada:**
```
JOBNAME  JOBID    OWNER   STATUS  CC/ABEND  STARTED
-------- -------- ------- ------- --------- --------------------
EBJCHAIN JOB12345 ELIEL   OUTPUT  CC 0000   2026-08-13 02:14:30
EBJVALD  JOB12340 ELIEL   OUTPUT  CC 0000   2026-08-13 02:10:05
```

**Lógica principal:**
```rexx
ADDRESS SDSF                    /* ativa o host SDSF          */
"ISFEXEC ST"                    /* abre a fila de status       */
/* percorre ISFROWS, lê JNAME, JOBID, OWNERID, RETCODE, etc.  */
```

**Variáveis SDSF usadas:** `JNAME`, `JOBID`, `OWNERID`, `RETCODE`, `STRTTIME`,
`ENDTIME`, `ISFTOTROWS`.

**Filtro por jobname** aplicado no REXX após leitura (sem SDSF filter syntax,
para compatibilidade máxima com z/OS 3.1 VSI).

**Integração:** EBCLI.rexx receberá opção `6. STATUS JOBS (EBSDSF)` para
invocar este script do menu interativo.

---

### 4.2 EBRXSQL.rexx — SELECT DB2 via RXSQL (operador)

**Localização:** `rexx/operador/EBRXSQL.rexx`

**Objetivo:** executar SELECTs DB2 ad-hoc a partir do TSO sem precisar abrir
SPUFI. Útil para diagnóstico rápido de estado de contas, saldos e lançamentos
durante investigação de incidentes.

**Interface:**
```
EX 'HLQ.DEV.REXX(EBRXSQL)'
```
O script exibe um menu de queries pré-definidas:

```
1. Saldo de uma conta     (SELECT CNT_SALDO FROM EMUNAH.CDCNT WHERE...)
2. Ultimos lancamentos     (SELECT * FROM EMUNAH.CDLCT ORDER BY...)
3. Contagem por status    (SELECT LCT_STATUS, COUNT(*) FROM EMUNAH.CDLCT...)
4. Consulta livre         (digitar SQL manualmente)
X. Sair
```

**Implementação:** usa `RXSQL` (IBM REXX/SQL interface para DB2) via
`ADDRESS DSNREXX` ou, quando não disponível, submete um job SPUFI-like via
`EXECIO` para `SYSIN` e captura `SYSPRINT`.

**Fallback:** se `RXSQL` não estiver disponível, exibe instrução para uso do
SPUFI com o SQL sugerido.

**Integração:** EBCLI.rexx receberá opção `7. CONSULTA DB2 (EBRXSQL)`.

---

## Fase 5 — EBOPS USS: API REST Node.js em z/OS USS

### Contexto

O EBOPS hoje roda como servidor Python/Flask no Windows (EBOPS local).
A Fase 5 cria um espelho REST em z/OS USS (Unix System Services), permitindo
que o EBOPS consuma informações direto do mainframe via HTTP, sem a camada
Zowe CLI intermediária para todas as chamadas.

### Stack escolhida

| Componente | Escolha | Justificativa |
|---|---|---|
| Runtime | Node.js 18 LTS | Disponível em z/OS USS como SMP/E feature package; IBM mantém port nativo |
| Framework | Express.js 4 | Sem dependências nativas, funciona em z/OS sem recompilação |
| DB2 driver | `ibm_db` npm package | Driver oficial IBM para z/OS; usa CLI/ODBC |
| Autenticação | HTTP Basic (MVP) | Suficiente para lab; em produção seria JWT + SAF RACF |

### Estrutura de arquivos

```
ebops/
  uss-api/
    package.json          <- dependências e scripts npm
    app.js                <- servidor Express, rota raiz
    routes/
      contas.js           <- GET /contas/:agencia/:conta
      lancamentos.js      <- GET /lancamentos/:agencia/:conta
      status.js           <- GET /status (healthcheck)
    middleware/
      auth.js             <- Basic Auth via RACF passthru
      logger.js           <- log para HFS file / SYSOUT
    config/
      db2.js              <- conexão ibm_db (DSN=DBD1)
    README-USS.md         <- instruções de setup no USS
```

### Rotas planejadas (MVP)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/status` | Healthcheck — retorna `{"status":"ok","ts":"..."}` |
| GET | `/contas/:ag/:ct` | Saldo e limite da conta via `SELECT` em `EMUNAH.CDCNT` |
| GET | `/lancamentos/:ag/:ct?limit=10` | Últimos N lançamentos de `EMUNAH.CDLCT` |
| POST | `/eventos/trf` | Registra evento de transferência (recebe JSON, escreve em TD EMTF) |

### Integração com EBOPS web (Python)

O `ebops_server.py` atual tem hardcoded `HLQ_JCL`, `HLQ_COBOL` etc. e usa Zowe
para todas as chamadas. Após a Fase 5:
- Chamadas de **leitura de dados** (saldo, extrato) passam pelo Node.js USS API.
- Chamadas de **submissão de jobs** continuam via Zowe CLI (que usa z/OSMF REST).
- O `ebops_server.py` ganha um flag `USE_USS_API=True` e uma função
  `_uss_get(path)` que faz `requests.get(http://192.168.100.150:3000/...)`.

### Setup no USS (passos)

```sh
# No OMVS (SSH ou TELNET 3270 OMVS):
cd /u/eliel/ebops-api
npm install          # instala express + ibm_db
node app.js &        # inicia em background na porta 3000

# Verificação:
curl http://localhost:3000/status
# {"status":"ok","subsystem":"DBD1","ts":"2026-08-13T02:00:00Z"}
```

---

## Fase 6 — HLASM: EBASMSUM + EBCOREDP

### Contexto

A camada HLASM demonstra conhecimento de linguagem Assembly System/390 e z/
Architecture — habilidade rara e muito valorizada em ambiente bancário para:
- Análise de dumps (ABEND S0C4, S0C7, SOC1, S222)
- Programas auxiliares de performance crítica
- Compreensão de como registros, endereços e masks funcionam

### 6.1 EBASMSUM.asm — Soma de vetor em registradores

**Localização:** `hlasm/EBASMSUM.asm`

**Objetivo educacional:** demonstrar uso de registradores gerais (R0–R15),
modo de endereçamento base+deslocamento, instruções de carga (`L`/`LH`),
aritmética (`AR`/`A`), loop com `BCT`, e `BALR`/`USING` para base register.

**Interface:** programa invocável via CALL ou diretamente como PGM= em JCL.
Recebe um vetor de fullwords (PL4) via PARM ou linkage section e retorna a soma
em R0 e no campo `RESULT` da DSECT.

**Estrutura planejada:**
```hlasm
EBASMSUM CSECT
         STM   R14,R12,12(R13)   save caller registers
         LR    R12,R15           base register
         USING EBASMSUM,R12
         LA    R13,SAVEAREA      local savearea
* ... setup, loop, sum, return ...
         LM    R14,R12,12(R13)   restore
         BR    R14               return to caller
SAVEAREA DS    18F
RESULT   DS    F
         END   EBASMSUM
```

**JCL de compilação:** `jcl/compile/EBASMJ.jcl` (PGM=ASMA90, depois IEWL).

---

### 6.2 EBCOREDP.asm — Core Dump / Register Snapshot

**Localização:** `hlasm/EBCOREDP.asm`

**Objetivo educacional:** rotina chamável por COBOL/Assembler que captura o
conteúdo dos 16 registradores gerais (R0–R15) e os formata como uma linha
hexadecimal legível, escrevendo em um `DD SYSOUT`. Simula o que um SNAP dump
ou ESPIE handler faz — fundamental para análise de ABENDs.

**Casos de uso no lab:**
- Chamar de EBVALI01 quando rejeita um registro (snapshot do estado dos regs)
- Demonstrar análise de dump: dado um SNAP output, identificar o endereço de
  retorno (R14), o endereço base (R12) e o programa que abendou

**Interface (CALL do COBOL):**
```cobol
CALL 'EBCOREDP' USING WS-SNAP-AREA
```

**Saída (na DD SNPRPT da JCL):**
```
EBCOREDP REGISTER SNAPSHOT - TASK 0001234
R00=00000000 R01=00A12F40 R02=00000000 R03=00A13000
R04=00A14200 R05=00000001 R06=00000000 R07=00000000
R08=00000000 R09=00000000 R10=00A15800 R11=00A16000
R12=00A17000 R13=00A18000 R14=00A19000 R15=00000000
PSW=078D1000 00A17004  EBCOREDP SNAP COMPLETE
```

**Técnicas HLASM demonstradas:**
- `STCM` / `STM` para captura de todos os registradores
- `UNPK` + `TR` para conversão hex→printable (técnica clássica z/OS)
- `PUT` via `DCBD` ou `OPEN`/`CLOSE` / `PUT` de um `DCB DSORG=PS`
- `SNAP` macro (alternativa mais simples para lab)

---

## Dependências entre fases

```
3.5 (DB2CONN) ──► 3.6 (MQPUT ETRF)
                    │
                    ▼
              4.1 EBSDSF ─────► EBCLI option 6
              4.2 EBRXSQL ────► EBCLI option 7
                    │
                    ▼
              5 USS API ──────► ebops_server.py USE_USS_API
                    │
                    ▼
              6.1 EBASMSUM ───► call test JCL EBASMJ
              6.2 EBCOREDP ───► CALL from EBVALI01 (opcional)
```

---

## Checklist geral de artefatos a criar

### Fase 3.5
- [ ] `cobol/online/EBCSSLD.cbl` — merge com versão DB2 de `ELIEL.EMUNAH/`; adicionar `WS-CSSL-LOG` estruturado
- [ ] `docs/logs/EMUNAH_STEP-3-5_ESLD-DB2CONN-APCT.txt` — ✅ criado nesta sessão
- [ ] Upload `EBCSSLD.cbl` atualizado para `ELIEL.EMUNAH.DEV.COBOL(EBCSSLD)`
- [ ] `git add jcl/compile/EBCSSLDJ.jcl` (resolver UU)

### Fase 3.6
- [ ] `cobol/online/EBCSTRF.cbl` — adicionar `WS-MQ-MSG` na WS e WRITEQ TD em `4000-CONFIRMAR-TRANSFERENCIA`
- [ ] `CEDA DEFINE TDQUEUE(EMTF)` no CSD grupo EMUNAH
- [ ] Registrar evidência em novo log STEP-3-6

### Fase 4
- [ ] `rexx/operador/EBSDSF.rexx` — novo arquivo
- [ ] `rexx/operador/EBRXSQL.rexx` — novo arquivo
- [ ] `rexx/operador/EBCLI.rexx` — adicionar opções 6 e 7

### Fase 5
- [ ] `ebops/uss-api/package.json`
- [ ] `ebops/uss-api/app.js`
- [ ] `ebops/uss-api/routes/contas.js`
- [ ] `ebops/uss-api/routes/lancamentos.js`
- [ ] `ebops/uss-api/routes/status.js`
- [ ] `ebops/uss-api/config/db2.js`
- [ ] `ebops/uss-api/README-USS.md`
- [ ] `ebops/ebops_server.py` — flag `USE_USS_API` + função `_uss_get()`

### Fase 6
- [ ] `hlasm/EBASMSUM.asm` — novo arquivo
- [ ] `hlasm/EBCOREDP.asm` — novo arquivo
- [ ] `jcl/compile/EBASMJ.jcl` — compile + link para EBASMSUM
- [ ] `jcl/compile/EBCOREDPJ.jcl` — compile + link para EBCOREDP

---

*Emunah Bank Lab — laboratório bancário mainframe para estudo, prática e portfólio profissional.*
