# [06] - RUNBOOKS OPERACIONAIS - EMUNAH BANK LAB

## Objetivo

Este documento reúne os procedimentos de diagnóstico, correção e reprocessamento para os principais incidentes do laboratório.

Seu papel é funcionar como um guia operacional de consulta rápida, mantendo coerência entre sintoma, causa provável, ação corretiva, necessidade de reprocessamento e evidências exigidas.

---

## Estrutura de leitura

Cada incidente é tratado a partir de seis perguntas principais:

1. qual é o sintoma observado?
2. qual é a causa provável?
3. como confirmar o diagnóstico?
4. qual ação corretiva deve ser executada?
5. é necessário reprocessar?
6. quais evidências precisam ser preservadas?

---

## Incidente: arquivo de entrada ausente

**Sintoma:** falha do job `EBJLOAD` e bloqueio da cadeia principal.  
**Causas prováveis:** ausência do dataset de entrada, nome incorreto, problema de upload ou erro de catálogo.  
**Diagnóstico:** verificar a existência de `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`, conferir nome, conteúdo e destino do upload.  
**Ação corretiva:** reenviar o arquivo, corrigir o nome ou o dataset de destino e repetir a checagem.  
**Reprocessamento:** reexecutar `EBJLOAD` após a correção.  
**Evidências:** spool do job, listagem do dataset e horário do reenvio.

---

## Incidente: layout inválido no arquivo de entrada

**Sintoma:** muitos rejeitos em `EBJVALD` ou RC elevado na validação.  
**Causas prováveis:** tamanho incorreto de registro, tipo inválido, valor incorreto, data fora do padrão ou conta inexistente.  
**Diagnóstico:** analisar o relatório de validação, `<HLQ>.EMUNAH.ARQ.REJEITO.SEQ` e comparar o layout com o copybook esperado.  
**Ação corretiva:** corrigir o arquivo, revisar a massa gerada ou ajustar a definição do layout.  
**Reprocessamento:** reexecutar `EBJVALD`.  
**Evidências:** registros rejeitados, motivo do rejeito e versão do layout utilizado.

---

## Incidente: conta inexistente ou inválida

**Sintoma:** rejeição na validação ou na aplicação.  
**Causas prováveis:** ausência da conta em `<HLQ>.EMUNAH.ARQ.CONTA.KSDS`, carga incompleta ou chave incorreta.  
**Diagnóstico:** consultar o arquivo de contas, verificar a carga inicial e conferir a chave da conta.  
**Ação corretiva:** corrigir a massa de entrada, recarregar o cadastro ou ajustar a composição da chave.  
**Reprocessamento:** usar `EBJREPR` ou repetir a etapa correspondente.  
**Evidências:** spool da etapa, prova da ausência da conta e massa corrigida.

---

## Incidente: falha na aplicação de lançamentos

**Sintoma:** falha do job `EBJPOST`.  
**Causas prováveis:** erro de lógica, conta bloqueada, saldo insuficiente ou falha de gravação.  
**Diagnóstico:** analisar spool, conferir o arquivo de contas, revisar os lançamentos válidos e observar o comportamento do programa.  
**Ação corretiva:** corrigir o programa ou a massa, recompilar e reenviar a versão corrigida.  
**Reprocessamento:** somente após confirmar que o estado do ambiente está consistente; em alguns casos, restaurar baseline antes da reaplicação.  
**Evidências:** spool, RC, registros afetados e indicação de impacto parcial ou total.

---

## Incidente: falha de conciliação

**Sintoma:** falha do job `EBJCONC` e impedimento do fechamento diário.  
**Causas prováveis:** divergência entre totais, erro no saldo consolidado, falha de reprocessamento ou geração incorreta de extrato.  
**Diagnóstico:** comparar totais de entrada e saída, quantidade de válidos e rejeitados, cálculo de saldo e conteúdo do extrato.  
**Ação corretiva:** localizar a divergência, corrigir a causa de origem e reexecutar a etapa adequada.  
**Reprocessamento:** nunca fechar o dia antes de a conciliação ficar consistente.  
**Evidências:** relatório de conciliação, totais esperados e apurados, logs dos jobs envolvidos.

---

## Incidente: job em hold ou não executado

**Sintoma:** job parado ou sem início de execução.  
**Causas prováveis:** status HOLD, dependência anterior não atendida ou falha em predecessor.  
**Diagnóstico:** verificar Zowe Explorer, SDSF e ordem da grade batch.  
**Ação corretiva:** liberar, reenviar ou corrigir a dependência anterior.  
**Reprocessamento:** retomar a partir do job afetado, desde que o estado anterior esteja consistente.  
**Evidências:** status do job, tela do SDSF e horários de parada/liberação.

---

## Incidente: reprocessamento de rejeitos

**Sintoma:** existência de registros corrigidos que ainda não foram reaplicados.  
**Causa típica:** erro anterior já identificado e corrigido.  
**Diagnóstico:** validar o arquivo corrigido, a causa do rejeito original e a segurança da reaplicação.  
**Ação corretiva:** preparar a massa corrigida, executar `EBJREPR` e validar impacto em saldo e extrato.  
**Evidências:** rejeitos originais, versão corrigida e spool do reprocessamento.

---

## Regra geral de evidências

Sempre que ocorrer uma falha, devem ser preservados:

- nome do job
- horário da ocorrência
- RC
- spool principal
- datasets afetados
- ação executada
- decisão sobre reprocessamento

---

## Papel dos runbooks no laboratório

Os runbooks reforçam que o projeto não é apenas um exercício de desenvolvimento. Eles formalizam uma postura de operação e suporte baseada em diagnóstico, rastreabilidade e correção controlada.
