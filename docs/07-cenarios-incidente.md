# Cenários de Incidente — Emunah Bank Lab

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

**Setup:** baseline restaurada, massa válida carregada e arquivo de entrada presente.  
**Jobs:** `EBJLOAD`, `EBJVALD`, `EBJPOST`, `EBJSALD`, `EBJEXTR`, `EBJCONC`, `EBJEOD`  
**Resultado esperado:** RC aceitável em toda a cadeia, conciliação correta e fechamento concluído.

---

## `missing-input`

Representa a ausência do arquivo de entrada no início do processamento.

**Setup:** baseline restaurada, mas sem envio de arquivo para `ARQ.ENTRADA.SEQ`.  
**Job principal:** `EBJLOAD`  
**Resultado esperado:** falha no início da cadeia, acionamento do runbook de arquivo ausente e bloqueio do processamento.

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

Representa divergência entre totais aplicados e saldo consolidado.

**Setup:** massa preparada com erro ou alteração proposital no cálculo.  
**Jobs afetados:** `EBJSALD`, `EBJCONC`  
**Resultado esperado:** falha de conciliação e bloqueio do fechamento.

---

## `late-file`

Representa atraso na chegada do arquivo do dia.

**Setup:** simular ausência inicial e chegada tardia posterior.  
**Resultado esperado:** atraso operacional, decisão entre aguardar, cancelar ou seguir com contingência, além de registro dessa decisão.

---

## `reprocess-required`

Representa a necessidade de reaplicar registros antes rejeitados e depois corrigidos.

**Setup:** gerar rejeitos controlados e preparar arquivo corrigido.  
**Job principal:** `EBJREPR`  
**Resultado esperado:** reaplicação correta, ajuste de totais e registro de evidência antes e depois.

---

## `validation-rc08`

Representa uma falha de validação relevante, mas não necessariamente técnica.

**Setup:** usar massa com erros de negócio significativos.  
**Job principal:** `EBJVALD`  
**Resultado esperado:** retorno elevado, necessidade de decisão operacional e eventual bloqueio da cadeia.

---

## Papel dos cenários no projeto

Os cenários de incidente ajudam a transformar o laboratório em um ambiente de prática realista. Eles permitem testar não apenas o “caminho feliz”, mas também as decisões de operação, o uso de evidências, a leitura de spool e a disciplina de reprocessamento.
