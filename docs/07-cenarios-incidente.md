# [07] - CENÁRIOS DE INCIDENTE - EMUNAH BANK LAB

## Objetivo

Este documento descreve cenários controlados de erro e os resultados esperados no laboratório.

Seu papel é apoiar testes operacionais, troubleshooting, treinamento de diagnóstico e validação de runbooks.

---

## Como ler os cenários

Cada cenário deve registrar:

- nome
- descrição
- setup
- jobs afetados
- resultado esperado
- runbook relacionado

---

## `normal-day`

Representa a execução normal do dia, sem falhas.

**Setup:** baseline restaurada, `CTL.STATUS=CLOSED` (ou vazio), massa válida em `STAGE.ENTRADA.SEQ` e bases GDG definidas.
**Jobs (ordem):** `EBJPRECK` → `EBJSOD` → `EBJBCKPD` → `EBJWAIT` → `EBJLOAD` → `EBJVALD` → `EBJPOST` → `EBJACCR` → `EBJCUTF` → `EBJSNAP` → `EBJCUTE` → `EBJCONC` → `EBJEXTR` → `EBJEOD`.
**Resultado esperado:** RC aceitável em toda a cadeia, transições `OPEN → EOTI → EOFI → CLOSED` consistentes, snapshot e extrato em GDG e conciliação three-way `OK` em `CONCIL.SEQ`.

---

## `missing-input`

Representa a ausência do arquivo de entrada no início do processamento.

**Setup:** baseline restaurada, mas sem envio de arquivo para `STAGE.ENTRADA.SEQ`.
**Job principal:** `EBJWAIT` (porteiro novo da intake).
**Resultado esperado:** falha no início da cadeia ainda na FASE 2, acionamento do runbook de arquivo ausente, `EBJLOAD` não chega a ser submetido e a cadeia não progride. `CTL.STATUS` permanece em `OPEN`.

---

## `invalid-layout`

Representa um arquivo de entrada com layout incorreto.

**Setup:** baseline restaurada e arquivo inválido enviado.  
**Job principal:** `EBJVALD`  
**Resultado esperado:** rejeitos, RC elevado ou processamento parcial, exigindo correção e possível reprocessamento.

---

## `duplicate-key`

Representa tentativa de gravação duplicada em arquivo chaveado.

**Setup:** massa com duplicidade controlada.  
**Job afetado:** qualquer etapa que grave em KSDS, como carga inicial ou fluxo específico.  
**Resultado esperado:** erro de gravação controlado, rejeição do registro e log de inconsistência.

---

## `wrong-disp`

Representa um JCL com parâmetro inadequado de alocação ou uso de dataset.

**Setup:** alteração proposital do JCL.  
**Resultado esperado:** erro de alocação, interrupção do job e spool com mensagens correspondentes.

---

## `hold-job`

Representa um job submetido, mas não liberado ou bloqueado por dependência.

**Setup:** simular hold ou dependência anterior não atendida.  
**Resultado esperado:** job parado, análise no Zowe Explorer e no SDSF, e acionamento do runbook apropriado.

---

## `saldo-inconsistente`

Representa divergência entre totais aplicados, snapshot de saldo e conciliação three-way.

**Setup:** massa preparada com erro ou alteração proposital no cálculo de accrual / postagem.
**Jobs afetados:** `EBJSNAP` (snapshot do dia), `EBJCONC` (conciliação three-way bloqueante).
**Resultado esperado:** `EBJCONC` grava linhas `DIVERGENTE` em `CONCIL.SEQ` (seção S2 ou S3), `EBJEOD` é bloqueado e o dia não fecha até a divergência ser resolvida — usar runbook de divergência three-way.

---

## `late-file`

Representa atraso na chegada do arquivo do dia.

**Setup:** simular ausência inicial e chegada tardia posterior.  
**Resultado esperado:** atraso operacional, decisão entre aguardar, cancelar ou seguir com contingência, além de registro dessa decisão.

---

## `reprocess-required`

Representa a necessidade de reaplicar registros antes rejeitados e depois corrigidos.

**Setup:** gerar rejeitos controlados (`REJEITOS.SEQ`), corrigi-los, e preparar `REPR.LANCTO.SEQ`.
**Jobs principais:** `EBJREPR` (revalida rejeitos corrigidos) seguido de `EBJRPOST` (reinjeta os recuperados em `EBPOST01`, fechando o ciclo).
**Pré-condição:** janela de input ainda aberta (`CTL.STATUS=EOTI`).
**Resultado esperado:** reaplicação correta, ajuste de totais e registro de evidência antes/depois (`AUDIT.SEQ`, `LANCTO.ESDS`).

---

## `cutoff-out-of-window`

Representa um cutoff disparado fora de ordem ou em duplicidade.

**Setup:** executar `EBJCUTF` ou `EBJCUTE` sem que a fase anterior tenha completado, ou disparar duas vezes seguidas.
**Jobs afetados:** `EBJCUTF`, `EBJCUTE`, `EBCTL01`.
**Resultado esperado:** `EBCTL01` recusa a transição inválida; runbook de cutoff fora de janela aciona reset controlado de `CTL.STATUS`.

---

## `gdg-allocation-fail`

Representa falha de alocação em uma das bases GDG.

**Setup:** simular base GDG não definida (esquecer `EBDEFGDG`) ou estourar limite de gerações.
**Jobs afetados:** `EBJBCKPD`, `EBJSNAP`, `EBJEXTR`, `EBJHKAUD`, `EBJHKREJ`.
**Resultado esperado:** falha de allocation com mensagem `IGD17xxx`, runbook de GDG aciona `LISTCAT` da base, ajuste de `LIMIT` e reexecução.

---

## `housekeeping-skip`

Representa um dia em que `AUDIT.SEQ` ou `REJEITOS.SEQ` cresce sem rotação.

**Setup:** suprimir os jobs de housekeeping por vários ciclos.
**Jobs afetados:** `EBJHKAUD`, `EBJHKREJ`, e indiretamente `EBJVALD`/`EBJPOST` (escrita lenta).
**Resultado esperado:** sequenciais cheios, alocação futura recusada, e necessidade de archive manual via `EBJHKAUD`/`EBJHKREJ` antes de retomar a cadeia.

---

## `validation-rc08`

Representa uma falha de validação relevante, mas não necessariamente técnica.

**Setup:** usar massa com erros de negócio significativos.  
**Job principal:** `EBJVALD`  
**Resultado esperado:** retorno elevado, necessidade de decisão operacional e eventual bloqueio da cadeia.

---

## Papel dos cenários no projeto

Os cenários de incidente ajudam a transformar o laboratório em um ambiente de prática realista. Eles permitem testar não apenas o “caminho feliz”, mas também as decisões de operação, o uso de evidências, a leitura de spool e a disciplina de reprocessamento.
