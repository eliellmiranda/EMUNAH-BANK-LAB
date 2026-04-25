# [06] - RUNBOOKS OPERACIONAIS - EMUNAH BANK LAB

## Objetivo

Este documento reúne os procedimentos de diagnóstico, correção e reprocessamento para os principais incidentes do laboratório.

Serve como guia operacional de consulta rápida, mantendo coerência entre sintoma, causa provável, ação corretiva, necessidade de reprocessamento e evidências exigidas.

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

## Incidente: CTL.STATUS inconsistente

**Sintoma:** `EBJPRECK` aborta ou um job no meio da cadeia recusa execução.  
**Causas prováveis:** ciclo anterior não fechou; status gravado manualmente; ciclo reiniciado sem reset.  
**Diagnóstico:** inspecionar `ARQ.CTL.STATUS` (IEBGENER SYSOUT ou ISPF BROWSE); conferir se o valor bate com a fase esperada.  
**Ação corretiva:** decidir se retoma do ponto onde parou (`EOTI`, `EOFI`) ou reseta o ciclo inteiro (`EBRESET` + `EBJSOD`).  
**Reprocessamento:** sim, a partir do job correspondente à fase esperada após correção do status.  
**Evidências:** conteúdo anterior do `CTL.STATUS`, data-hora da decisão, spool de `EBJPRECK`.

---

## Incidente: STAGE.ENTRADA.SEQ ausente ou vazio (EBJWAIT falha)

**Sintoma:** `EBJWAIT` retorna com RC alto, cadeia para antes de `EBJLOAD`.  
**Causas prováveis:** upload não aconteceu; arquivo enviado com nome errado; arquivo vazio (0 registros).  
**Diagnóstico:** `LISTCAT` do STAGE e `ICETOOL COUNT` sobre o conteúdo.  
**Ação corretiva:** reenviar o arquivo para `STAGE.ENTRADA.SEQ` e reexecutar `EBJWAIT`.  
**Reprocessamento:** `EBJWAIT` → `EBJLOAD` em sequência, cadeia segue normal.  
**Evidências:** spool do `EBJWAIT`, timestamp do upload, tamanho do arquivo.

---

## Incidente: layout inválido no arquivo de entrada

**Sintoma:** muitos rejeitos em `EBJVALD` ou RC elevado na validação.  
**Causas prováveis:** tamanho incorreto de registro, tipo inválido, valor incorreto, data fora do padrão ou conta inexistente.  
**Diagnóstico:** analisar `ARQ.REJEITOS.SEQ` e comparar layout com copybook esperado.  
**Ação corretiva:** corrigir arquivo ou ajustar a definição do layout.  
**Reprocessamento:** reexecutar `EBJVALD` → `EBJPOST`.  
**Evidências:** registros rejeitados, motivo do rejeito e versão do layout utilizado.

---

## Incidente: conta inexistente ou inválida

**Sintoma:** rejeição na validação ou na aplicação.  
**Causas prováveis:** ausência da conta em `ARQ.CONTA.KSDS`, carga incompleta ou chave incorreta.  
**Diagnóstico:** consultar `CONTA.KSDS` (ex.: `EBSALD01` utilitário), verificar a carga e conferir a chave.  
**Ação corretiva:** corrigir massa de entrada, recarregar o cadastro ou ajustar composição da chave.  
**Reprocessamento:** `EBJREPR` → `EBJRPOST` ou repetir etapa.  
**Evidências:** spool da etapa, prova da ausência da conta e massa corrigida.

---

## Incidente: falha na aplicação de lançamentos (EBJPOST)

**Sintoma:** falha do job `EBJPOST`.  
**Causas prováveis:** erro de lógica, conta bloqueada, saldo insuficiente, falha de gravação em KSDS.  
**Diagnóstico:** spool, `ARQ.AUDIT.SEQ`, conferência de `ARQ.CONTA.KSDS`.  
**Ação corretiva:** corrigir programa ou massa, recompilar, reenviar e, se necessário, restaurar baseline a partir de `BKP.*.GDG`.  
**Reprocessamento:** somente após confirmar que o estado do ambiente está consistente.  
**Evidências:** spool, RC, registros afetados, indicação de impacto parcial ou total, nome da geração de backup usada.

---

## Incidente: cutoff fora de janela (EBJCUTF/EBJCUTE)

**Sintoma:** cutoff disparado sem que a etapa anterior tenha terminado, ou disparado em duplicidade.  
**Causas prováveis:** execução manual fora de ordem; falha de dependência.  
**Diagnóstico:** conferir `CTL.STATUS` antes e depois; revisar janela batch.  
**Ação corretiva:** se o status ficou à frente, voltar o `CTL.STATUS` para o valor correto via utilitário (`EBCTL01`) e repetir os jobs pendentes.  
**Reprocessamento:** conforme o estado — normalmente retomar a partir do cutoff afetado.  
**Evidências:** spool do cutoff, `CTL.STATUS` antes/depois, trilha `AUDIT.SEQ`.

---

## Incidente: divergência na conciliação three-way (EBJCONC)

**Sintoma:** `EBJCONC` grava linhas `DIVERGENTE` em `ARQ.CONCIL.SEQ`; `EBJEOD` fica bloqueado.  
**Causas prováveis:** rejeitos fora do esperado, erro em `EBPOST01`, snapshot (`EBSNAP01`) inconsistente, accruals duplicados.  
**Diagnóstico:** ler `CONCIL.SEQ` seção a seção (S1 entrada vs válidos+rejeitos; S2 válidos vs postados; S3 saldo inicial+líquidos vs saldo final) e localizar onde a divergência aparece.  
**Ação corretiva:** reexecutar o módulo da seção em que a divergência aparece — ou restaurar baseline.  
**Reprocessamento:** nunca fechar o dia antes de a conciliação ficar consistente.  
**Evidências:** `CONCIL.SEQ`, totais esperados e apurados, logs dos jobs envolvidos, geração usada do `SALDO.GDG`.

---

## Incidente: falha de allocation em GDG

**Sintoma:** `BKP`, `SALDO` ou `EXTRATO` falham com erro de allocation de geração.  
**Causas prováveis:** base GDG não definida, `MODEL.DSCB` ausente, limite de gerações atingido sem `SCRATCH`.  
**Diagnóstico:** `LISTCAT ENTRIES(...GDG) ALL` para inspecionar base e gerações.  
**Ação corretiva:** rodar `EBDEFGDG` para (re)criar a base, ajustar `LIMIT`, recalcular retenção.  
**Reprocessamento:** reexecutar o job que falhou.  
**Evidências:** saída de `LISTCAT`, spool do job, nome do GDG afetado.

---

## Incidente: housekeeping falhou (EBJHKAUD/EBJHKREJ)

**Sintoma:** `AUDIT.SEQ` ou `REJEITOS.SEQ` crescendo indefinidamente, ou steps `ARCHAUD`/`DELAUD`/`ALLOCAUD` em erro.  
**Causas prováveis:** geração não alocada, dataset em uso por outro job, limite do GDG.  
**Diagnóstico:** `LISTCAT` do GDG de backup, espaço alocado, spool completo do housekeeping.  
**Ação corretiva:** encerrar jobs concorrentes, ajustar base GDG (`EBDEFGDG`), reexecutar housekeeping.  
**Reprocessamento:** executar `EBJHKAUD`/`EBJHKREJ` manualmente.  
**Evidências:** spool dos três steps (`ARCH`/`DEL`/`ALLOC`), `LISTCAT` do GDG, tamanho do sequencial antes/depois.

---

## Incidente: falha de conciliação (geral)

**Sintoma:** falha de execução do `EBJCONC` (RC alto, abend) — distinto de "divergência".  
**Causas prováveis:** arquivo de entrada ausente (`SALDO.GDG`, `LANCTO.ESDS`), erro de abertura, programa mal linkado.  
**Diagnóstico:** spool, conferência de geração do `SALDO.GDG` usada.  
**Ação corretiva:** corrigir dependência de entrada ou o programa; reexecutar.  
**Reprocessamento:** reexecutar `EBJCONC` após corrigir a causa.  
**Evidências:** spool, geração do `SALDO.GDG`, LRECL do `CONCIL.SEQ`.

---

## Incidente: job em hold ou não executado

**Sintoma:** job parado ou sem início de execução.  
**Causas prováveis:** status HOLD, dependência anterior não atendida, falha em predecessor.  
**Diagnóstico:** Zowe Explorer, SDSF, ordem da grade batch.  
**Ação corretiva:** liberar, reenviar ou corrigir a dependência anterior.  
**Reprocessamento:** retomar a partir do job afetado, desde que o estado anterior esteja consistente.  
**Evidências:** status do job, tela do SDSF, horários de parada/liberação.

---

## Incidente: reprocessamento de rejeitos

**Sintoma:** existem registros corrigidos que ainda não foram reaplicados.  
**Causa típica:** erro anterior identificado e corrigido.  
**Diagnóstico:** validar massa corrigida, causa do rejeito original, segurança da reaplicação.  
**Ação corretiva:** preparar massa em `ARQ.REPR.LANCTO.SEQ`, executar `EBJREPR` e `EBJRPOST`, validar impacto em saldo e extrato.  
**Evidências:** rejeitos originais, versão corrigida, spool do reprocessamento, efeitos em `CONCIL.SEQ` seguinte.

---

## Procedimento: reset de ambiente (EBRESET vs EBRESETF)

O laboratório oferece dois utilitários de reset, com escopos diferentes. Escolher o errado **destrói trabalho** (reset de fábrica acidental) ou **deixa sujeira** (reset de ciclo quando o ambiente já está corrompido).

### Decisão rápida

| Pergunta | Sim → use |
|---|---|
| O ciclo do dia falhou e você quer rodar de novo com os mesmos clientes/contas? | `EBRESET` |
| Os masters (`CLIENTE.KSDS` ou `CONTA.KSDS`) estão suspeitos de corrupção? | `EBRESETF` |
| Você quer demonstrar o lab "do zero" para alguém? | `EBRESETF` |
| `CTL.STATUS` está num estado inconsistente que você não consegue corrigir? | `EBRESET` (mantém masters) ou `EBRESETF` (se quiser zero absoluto) |
| Você só quer apagar rejeitos/auditoria do dia anterior? | `EBRESET` |

### O que cada um toca

| Coisa | `EBRESET` | `EBRESETF` |
|---|---|---|
| `ARQ.LANCTO.ESDS` | DELETE + DEFINE | DELETE + DEFINE |
| `ARQ.ENTRADA.SEQ`, `ENTRADA.TRAILER.SEQ` | recria vazio | recria vazio |
| `ARQ.REJEITOS.SEQ`, `AUDIT.SEQ`, `CONCIL.SEQ` | recria vazio | recria vazio |
| `ARQ.ACCR.MOV.SEQ`, `FECHTO.SEQ` | apaga (re-aloc dinâmica) | apaga (re-aloc dinâmica) |
| `ARQ.REPR.LANCTO.SEQ`, `REPR.REJPERM.SEQ` | recria vazio | recria vazio |
| **`ARQ.CLIENTE.KSDS`, `ARQ.CONTA.KSDS`** | **preserva** | **DELETE + DEFINE** |
| **`ARQ.CTL.STATUS`, `ARQ.CTL.PROCDATE`** | **preserva** | **apaga e recria vazio** |
| **`STAGE.ENTRADA.SEQ`** | **preserva** | **apaga e recria vazio** |
| **GDGs (`SALDO`, `EXTRATO`, `BKP.*`)** | **preserva** | **GDG FORCE + DEFINE base vazia** |
| `SEED.*`, `PARM.JUROS.CONFIG` | não toca | não toca |
| `DEV.COBOL/COPY/JCL/LOADLIB/REXX` | não toca | não toca |

### Sequência pós-reset

**Após `EBRESET`** (reset de ciclo):

1. Conferir `ARQ.CTL.STATUS` — se ficou em estado intermediário, ajustar para `CLOSED` via `EBCTL01` ou edição manual.
2. Re-promover o arquivo do dia (se necessário): `EBJWAIT` lê `STAGE.ENTRADA.SEQ` (preservado), `EBJLOAD` repopula `ARQ.ENTRADA.SEQ`.
3. Reexecutar a cadeia: `EBJPRECK → EBJSOD → EBJBCKPD → EBJWAIT → EBJLOAD → EBJVALD → EBJPOST → EBJACCR → EBJCUTF → EBJSNAP → EBJCUTE → EBJCONC → EBJEXTR → EBJEOD`.

**Após `EBRESETF`** (reset de fábrica):

1. Recarregar os masters: submeter `EBJCLLD` (executa `EBCLLOAD` lendo `SEED.CLIENTES.SEQ` e `SEED.CONTAS.SEQ`).
2. Confirmar via `LISTRESF` no spool que os KSDS têm registros e os GDGs estão em `LIMIT(0)`.
3. Fazer upload de um arquivo do dia para `STAGE.ENTRADA.SEQ` (via Zowe ou Zowe Explorer).
4. Reexecutar a cadeia normal.

### Quando os dois falham

Se `EBRESETF` também não resolve, suspeitar de:

- catálogo do z/OS com entradas órfãs → `LISTCAT` e `DELETE NOSCRATCH` manual
- `MODEL.DSCB` ausente (necessário para alocar gerações GDG) → recriar via `EBALLOC`
- limite do GDG configurado com `EMPTY` em vez de `NOEMPTY` → reexecutar `EBDEFGDG`

Nesse cenário, o caminho é o reseed completo do ambiente: `EBALLOC + EBDEFGDG + EBSEED + EBJCLLD`.

### Evidências a preservar

- spool do `EBRESET` ou `EBRESETF` com o `LISTCAT` final dos datasets afetados
- valor de `ARQ.CTL.STATUS` antes da decisão de reset
- motivo da decisão (ciclo falhou? master corrompido? demonstração?)
- nome do operador e timestamp

---

## Regra geral de evidências

Sempre que ocorrer uma falha, devem ser preservados:

- nome do job e step
- horário da ocorrência
- RC
- valor de `ARQ.CTL.STATUS` no momento da falha
- spool principal
- datasets afetados (incluindo geração GDG, quando aplicável)
- ação executada
- decisão sobre reprocessamento

---

## Papel dos runbooks no laboratório

Os runbooks reforçam que o projeto não é apenas um exercício de desenvolvimento. Eles formalizam uma postura de operação e suporte baseada em diagnóstico, rastreabilidade e correção controlada — com `CTL.STATUS`, GDGs e housekeeping transformando "código que roda" em "ambiente que se mantém".