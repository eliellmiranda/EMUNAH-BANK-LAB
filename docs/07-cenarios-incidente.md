# [07] - CENÁRIOS DE INCIDENTE - EMUNAH BANK LAB

## Objetivo
Este documento descreve cenários controlados de erro e os resultados esperados no laboratório. Seu papel é apoiar testes operacionais, troubleshooting, treinamento de diagnóstico e validação de runbooks.

---

## Como ler os cenários
Cada cenário registra: Nome, Descrição, Setup, Jobs Afetados, Resultado Esperado e o Runbook Relacionado para correção.

---

## 🟢 `normal-day` (Caminho Feliz)
Representa a execução normal do dia, sem falhas.
- **Setup:** Baseline restaurada, `CTL.STATUS=CLOSED` e massa válida em `STAGE.ENTRADA.SEQ`.
- **Jobs (Ordem):** `EBJPRECK` → `EBJSOD` → `EBJBCKPD` → `EBJWAIT` → `EBJLOAD` → `EBJVALD` → `EBJPOST` → `EBJACCR` → `EBJCUTF` → `EBJSNAP` → `EBJCUTE` → `EBJCONC` → `EBJEXTR` → `EBJEOD`.
- **Resultado esperado:** Todos os jobs com RC 0000 ou 0004; transições de status consistentes; conciliação `OK`.

---

## 🔴 `missing-input`
Representa a ausência do arquivo de entrada no início do processamento.
- **Setup:** `STAGE.ENTRADA.SEQ` inexistente ou vazio.
- **Job principal:** `EBJWAIT` (File-watcher).
- **Resultado esperado:** Job `EBJWAIT` falha (RC 0008); cadeia bloqueada antes de `EBJLOAD`.
- **Runbook:** "Incidente: STAGE.ENTRADA.SEQ ausente ou vazio".

---

## 🟡 `invalid-layout`
Arquivo de entrada com layout fora do padrão esperado.
- **Setup:** Upload de arquivo com LRECL diferente de 120 ou tipos de dados inválidos.
- **Job principal:** `EBJVALD`.
- **Resultado esperado:** RC elevado em `EBJVALD`; registros gravados em `ARQ.REJEITOS.SEQ`.
- **Runbook:** "Incidente: layout inválido no arquivo de entrada".

---

## 🔴 `saldo-inconsistente`
Divergência entre totais de entrada, aplicação e saldo final.
- **Setup:** Massa preparada com valores que não batem com o saldo anterior ou erro induzido no cálculo de juros.
- **Jobs afetados:** `EBJSNAP` e `EBJCONC`.
- **Resultado esperado:** `EBJCONC` grava `DIVERGENTE` em `ARQ.CONCIL.SEQ`; `EBJEOD` é bloqueado.
- **Runbook:** "Incidente: divergência na conciliação three-way".

---

## 🟠 `reprocess-required`
Necessidade de reaplicar registros corrigidos durante a janela operacional.
- **Setup:** Corrigir registros rejeitados em `ARQ.REPR.LANCTO.SEQ`.
- **Jobs principais:** `EBJREPR` (validação) e `EBJRPOST` (aplicação).
- **Resultado esperado:** Saldo final atualizado e nova conciliação consistente após a reinjeção.
- **Runbook:** "Incidente: reprocessamento de rejeitos".

---

## 🔴 `gdg-allocation-fail`
Falha de alocação em bases de dados geracionais.
- **Setup:** Deletar a base GDG ou estourar o `LIMIT` de gerações sem `SCRATCH`.
- **Jobs afetados:** `EBJBCKPD`, `EBJSNAP` ou `EBJEXTR`.
- **Resultado esperado:** JCL Error ou falha de alocação (IGD17xxx).
- **Runbook:** "Incidente: falha de allocation em GDG".

---

## 🟠 `cutoff-out-of-window`
Tentativa de fechamento de fase fora de ordem.
- **Setup:** Submeter `EBJCUTF` (Cutoff Financeiro) antes do término do `EBJPOST`.
- **Resultado esperado:** `EBCTL01` (Gerenciador de Status) aborta a execução por transição inválida.
- **Runbook:** "Incidente: cutoff fora de janela".

---

## Papel dos cenários no projeto
Os cenários de incidente permitem testar não apenas o “caminho feliz”, mas a resiliência operacional do banco. Eles validam a eficácia da disciplina de reprocessamento e o uso correto dos utilitários de Reset (`EBRESET/EBRESETF`).