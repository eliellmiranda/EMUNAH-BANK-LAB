# Runbook — JES2 Spool Cheio / SYS1.LOGREC Cheio
### EMUNAH-BANK-LAB — Hercules Hyperion, z/OS 3.1 (emulado) — sistema VS01

---

## 1. Escopo

| Item | Valor |
|---|---|
| Sistema | VS01 (host 192.168.100.150) |
| Plataforma | Hercules Hyperion, z/OS 3.1 emulado |
| HLQ do laboratório | ELIEL.EMUNAH |
| Datasets críticos | SYS1.LOGREC, spool JES2, checkpoint JES2 |

---

## 2. Sintomas

- `$HASP646 nn.nnnn PERCENT SPOOL UTILIZATION` acima de 90%
- `$HASP050 JES2 RESOURCE SHORTAGE OF TGS`
- Jobs em `STATUS=(AWAITING CONVERSION)` — não conseguem converter por falta de espaço de spool
- Jobs acumulando em `STATUS=(AWAITING PURGE)` / saída não purgada
- Durante uma tentativa de parada do JES2: `$HASP607 JES2 NOT DORMANT -- MEMBER DRAINING` e/ou `$HASP623 MEMBER DRAINING`
- Em caso extremo: `$HASP095 JES2 CATASTROPHIC ABEND, CODE=S02D`

---

## 3. Diagnóstico (nesta ordem)

1. `$D SPOOL` — utilização percentual do spool
2. `$D Q` — contagem de jobs por fila (CNV / INP / OUT / PPU etc.)
3. `$D JQ,SPL=(%>1)` — **quais jobs** estão consumindo mais de 1% do spool (aponta o culpado direto — mais útil que os dois comandos acima juntos)
4. `$D JES2` — status geral do subsistema
5. Se houver suspeita de shutdown travado: `D R,R,ALL` — mensagens WTOR pendentes (nunca responder às cegas antes de ver isso)

---

## 4. Causa raiz mais provável — não é só "o spool encheu"

Quando o incidente envolve `MEMBER DRAINING` seguido de abend, o gatilho normalmente **não é a % de spool isoladamente**. É uma tentativa de parar o JES2 (`$PJES2`) enquanto o OMVS/USS (address spaces `BPXAS`) ainda estava ativo — o JES2 fica preso esperando esses address spaces encerrarem, e isso pode escalar até um abend forçado (`S02D`) e IPL.

**Prevenção concreta:** sempre `F OMVS,SHUTDOWN` (e confirmar que os BPXAS terminaram) **antes** de `$PJES2`. Se você tem uma sequência automática de shutdown (COMMNDxx ou script), garanta que o comando de parada do OMVS vem antes do `$PJES2` nela — essa é a correção que realmente evita a repetição, não apenas monitorar o percentual do spool.

LOGREC cheio e spool cheio são datasets/mecanismos separados — trate-os como **sintomas paralelos** de um problema maior (ex: job em loop) até ter evidência de timestamp no SYSLOG que mostre um causando o outro.

---

## 5. Ações de recuperação

| Situação | Ação |
|---|---|
| `AWAITING PURGE` acumulando | Purgar via `$P J'jobname'` (job específico) ou pelo SDSF (ação `P` no painel ST) |
| `AWAITING CONVERSION` acumulando | Verificar espaço de spool antes de liberar mais jobs para conversão |
| `MEMBER DRAINING` travado | **Não** responder comandos às cegas. Rodar `D R,R,ALL` primeiro. Verificar se há BPXAS/OMVS ainda ativos |
| `$HASP095` / abend catastrófico do JES2 | Registrar horário, código (ex: `S02D`) e gerar dump. Um IPL costuma ser necessário para um restart limpo do JES2 |
| Spool ≥ 95% | Rodar **EBHKSPL** — se severidade = 12, avaliar **EBHKPUR** (começar sempre em modo `REPORT`) |

Cancelamento/purge pontual de um job específico:
```
$CJ'nomedojob'        (cancela por nome)
$CJ###,P              (cancela por número e já purga a saída retida)
$P OJOBQ,Q=classe,DAYS>N   (purga em massa saída de uma classe com mais de N dias)
```

---

## 6. Housekeeping preventivo — rotinas EBHKxxx

| Rotina | Tipo | Função | Frequência sugerida |
|---|---|---|---|
| **EBHKLOG** | JCL | EREP (offload/relatório) + limpeza do SYS1.LOGREC | Semanal, ou quando LOGREC estiver enchendo |
| **EBHKSPL** | JCL + REXX | Monitor de spool com severidade (0/4/8/12) e lista dos maiores consumidores | De hora em hora (manual ou script em loop) |
| **EBHKPUR** | REXX | Purga seletiva por prefixo liberado, com modo `REPORT` (dry-run) e `PURGE` | Sob demanda, disparado pelo EBHKSPL em severidade crítica |

**Por que não uma rotina separada para backup/checkpoint (EBHKBKP/EBHKCHK):** o histórico do LOGREC já fica preservado pelo EBHKLOG (fase EREP), e o backup de nível de imagem DASD já está coberto pela sua estratégia de UPS/backup do Hercules. Um backup "ao vivo" do checkpoint do JES2 via cópia direta (IEBGENER) não é seguro enquanto o JES2 está de pé — se quiser isso no futuro, é melhor via reconfiguração controlada de checkpoint do que copiar o dataset em uso.

**Política de segurança do EBHKPUR:** whitelist por **inclusão** — só mexe em jobs cujo nome comece com um prefixo liberado (`TSU`, `TEST`, `TMP`, `USR`, `EBJ`, `EBHK`) e que estejam em status `OUTPUT`/`PURGE`. Qualquer STC fora disso (JES2, TCPIP, DBB, DBBS, IMS*, CICS*, RACF etc.) é preservado por padrão — não é preciso listar tudo que é crítico, só o que é seguro purgar.

**Agendamento:** este é um laboratório sem scheduler tipo OPC/Control-M. O mais simples é submeter o EBHKSPL manualmente ou via um started task em loop com `WAIT`. O JES2 também aceita comandos automáticos com `T()`/`I()` (horário de início/intervalo) se você quiser automatizar só a parte de exibição de comandos.

---

## 7. Quando um IPL é realmente necessário

- JES2 sofre abend catastrófico (`S02D`) e não consegue reiniciar (hot/warm start falha)
- `MEMBER DRAINING` trava indefinidamente mesmo depois de tratar OMVS/BPXAS
- Como último recurso, depois de esgotadas as ações da seção 5

---

## 8. Checklist rápido (para colar no console de operação)

```
[ ] $D SPOOL
[ ] $D Q
[ ] $D JQ,SPL=(%>1)                 -> identificar quem consome mais spool
[ ] Antes de parar o JES2: F OMVS,SHUTDOWN primeiro, DEPOIS $PJES2
[ ] Registrar com horário: $HASP050 / $HASP607 / $HASP623 / $HASP095
[ ] Rodar EBHKSPL -> anotar severidade
[ ] Se severidade = 12: EBHKPUR REPORT antes de EBHKPUR PURGE
[ ] Se precisar limpar LOGREC: rodar EBHKLOG (EREP sempre antes do clear)
```

---

## Apêndice A — Setup único (rodar uma vez, antes do primeiro EBHKLOG)

```jcl
//DEFGDG   JOB (ACCT),'DEFINE GDG BASE',CLASS=A,MSGCLASS=H,
//             NOTIFY=&SYSUID
//STEP1    EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
  DEFINE GDG (NAME(ELIEL.EMUNAH.EBHKLOG.RPT) -
       LIMIT(14)                             -
       NOEMPTY                               -
       SCRATCH)
/*
```

## Apêndice B — Pontos a confirmar no seu ambiente antes de rodar

- Nome real do dataset LOGREC (`SYS1.LOGREC` é o padrão, mas confira no seu `IEASYSxx`/PARMLIB — pode estar com HLQ próprio)
- Biblioteca onde o REXX EBHKSPL/EBHKPUR vai residir (SYSEXEC no EBHKSPL.jcl)
- Nomes exatos das stem variables de data/idade no painel `ST` do seu SDSF — digite `COLSHELP` dentro do painel para ver os nomes reais no seu release, caso queira acrescentar filtro por idade no EBHKPUR
- `CLASS=A,MSGCLASS=H` nos JOB cards são placeholders — ajuste para as classes reais do seu VS01

---

*Correções aplicadas em relação à primeira versão deste runbook: utilitário de limpeza do LOGREC corrigido para IFCDIP00 (com passo de EREP antes), sintaxe de comandos de purge/cancelamento corrigida, causa raiz do MEMBER DRAINING associada à sequência de shutdown OMVS/JES2 em vez de apenas ao percentual de spool, e rotina de purga reescrita em REXX (SDSF não é acessível via COBOL).*
