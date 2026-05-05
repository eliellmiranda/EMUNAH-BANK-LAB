# [06] - RUNBOOKS OPERACIONAIS - EMUNAH BANK LAB

## Objetivo
Este documento reúne os procedimentos de diagnóstico, correção e reprocessamento para os principais incidentes do laboratório. Serve como guia operacional de consulta rápida, mantendo coerência entre sintoma, causa provável, ação corretiva, necessidade de reprocessamento e evidências exigidas.

---

## Estrutura de Leitura
Cada incidente é tratado a partir de seis perguntas principais:
1. Qual é o sintoma observado?
2. Qual é a causa provável?
3. Como confirmar o diagnóstico?
4. Qual ação corretiva deve ser executada?
5. É necessário reprocessar?
6. Quais evidências precisam ser preservadas?

---

## Incidente: CTL.STATUS inconsistente
* **Sintoma:** `EBJPRECK` aborta ou um job no meio da cadeia recusa execução.
* **Causas prováveis:** Ciclo anterior não fechou; status gravado manualmente; ciclo reiniciado sem reset.
* **Diagnóstico:** Inspecionar `ARQ.CTL.STATUS` (via IEBGENER SYSOUT ou ISPF BROWSE); conferir se o valor bate com a fase esperada.
* **Ação corretiva:** Decidir se retoma do ponto onde parou (`EOTI`, `EOFI`) ou reseta o ciclo inteiro (`EBRESET` + `EBJSOD`).
* **Reprocessamento:** Sim, a partir do job correspondente à fase esperada após correção do status.
* **Evidências:** Conteúdo anterior do `CTL.STATUS`, data-hora da decisão, spool de `EBJPRECK`.

---

## Incidente: STAGE.ENTRADA.SEQ ausente ou vazio
* **Sintoma:** `EBJWAIT` retorna com RC alto, cadeia para antes de `EBJLOAD`.
* **Causas prováveis:** Upload não aconteceu; arquivo enviado com nome errado; arquivo vazio (0 registros).
* **Diagnóstico:** `LISTCAT` do STAGE e `ICETOOL COUNT` sobre o conteúdo.
* **Ação corretiva:** Reenviar o arquivo para `STAGE.ENTRADA.SEQ` e reexecutar `EBJWAIT`.
* **Reprocessamento:** Sequência normal a partir de `EBJWAIT` → `EBJLOAD`.
* **Evidências:** Spool do `EBJWAIT`, timestamp do upload, tamanho do arquivo.

---

## Incidente: Layout inválido no arquivo de entrada
* **Sintoma:** Muitos rejeitos em `EBJVALD` ou RC elevado na validação.
* **Causas prováveis:** LRECL incorreto, tipo inválido, valor fora do padrão ou conta inexistente.
* **Diagnóstico:** Analisar `ARQ.REJEITOS.SEQ` e comparar layout com copybook esperado.
* **Ação corretiva:** Corrigir arquivo ou ajustar a definição do layout.
* **Reprocessamento:** Reexecutar `EBJVALD` → `EBJPOST`.
* **Evidências:** Registros rejeitados, motivo do rejeito e versão do layout utilizado.

---

## Incidente: Falha na aplicação de lançamentos (EBJPOST)
* **Sintoma:** Falha do job `EBJPOST`.
* **Causas prováveis:** Erro de lógica, conta bloqueada, saldo insuficiente, falha de gravação em KSDS.
* **Diagnóstico:** Spool, `ARQ.AUDIT.SEQ`, conferência de `ARQ.CONTA.KSDS`.
* **Ação corretiva:** Corrigir programa ou massa, recompilar, reenviar e, se necessário, restaurar baseline a partir de `BKP.*.GDG`.
* **Reprocessamento:** Somente após confirmar que o estado do ambiente está consistente.
* **Evidências:** Spool, RC, registros afetados, indicação de impacto parcial ou total, nome da geração de backup usada.

---

## Incidente: Divergência na conciliação three-way (EBJCONC)
* **Sintoma:** `EBJCONC` grava linhas `DIVERGENTE` em `ARQ.CONCIL.SEQ`; `EBJEOD` fica bloqueado.
* **Causas prováveis:** Rejeitos fora do esperado, erro em `EBPOST01`, snapshot inconsistente.
* **Diagnóstico:** Ler `CONCIL.SEQ` por seções (Entrada vs Válidos+Rejeitos; Válidos vs Postados; Saldo Inicial vs Final).
* **Ação corretiva:** Reexecutar o módulo da seção divergente ou restaurar baseline.
* **Reprocessamento:** Nunca fechar o dia antes de a conciliação ficar consistente.
* **Evidências:** `CONCIL.SEQ`, totais esperados vs apurados, logs dos jobs envolvidos.

---

## Procedimento: Reset de Ambiente (EBRESET vs EBRESETF)

| Pergunta | Sim → Use |
| :--- | :--- |
| O ciclo do dia falhou e quero rodar de novo mantendo clientes/contas? | **`EBRESET`** |
| Os masters (`CLIENTE.KSDS` ou `CONTA.KSDS`) estão corrompidos? | **`EBRESETF`** |
| Quero demonstrar o lab "do zero" (Estado Zero)? | **`EBRESETF`** |
| O `CTL.STATUS` está em estado impossível de corrigir manualmente? | **`EBRESETF`** |

### Impacto nos Arquivos

| Coisa | `EBRESET` (Ciclo) | `EBRESETF` (Fábrica) |
| :--- | :--- | :--- |
| `ARQ.LANCTO.ESDS` | DELETE + DEFINE | DELETE + DEFINE |
| `ARQ.CLIENTE.KSDS / CONTA.KSDS` | **Preserva** | DELETE + DEFINE |
| `ARQ.CTL.STATUS / PROCDATE` | **Preserva** | Apaga e recria vazio |
| `GDGs (SALDO, EXTRATO, BKP)` | **Preserva** | Force Delete + Redefine |

### Sequência pós-reset
* **Após `EBRESET`:** Ajustar status para `CLOSED` via `EBCTL01` e reexecutar a partir de `EBJPRECK`.
* **Após `EBRESETF`:** Obrigatoriamente executar `EBJCLLD` para recarregar o cadastro (Seed) antes de processar o dia.

---

## Regra Geral de Evidências
Sempre que ocorrer uma falha, devem ser preservados:
* Nome do job e step.
* Código de Retorno (RC) e horário.
* Valor de `ARQ.CTL.STATUS` no momento da falha.
* Spool principal e datasets afetados (incluindo geração GDG).