# CASE-006 — Implementação do JCL EBJSALD: arquivo criado vazio, populado com DDs do EBSALD01

**Projeto:** Emunah Bank Lab  
**Artefato afetado:** `jcl/batch/EBJSALD.jcl`  
**Data de criação do arquivo:** 2026-03-12  
**Data da alteração:** 2026-03-15  
**Categoria:** Implementação / JCL / Batch  
**Impacto:** Habilitação do step de saldo na cadeia batch — `EBJPOST` → **`EBJSALD`** → `EBJEXTR` → `EBJCONC`

---

## 1. Contexto

O `EBJSALD` é o job responsável por executar o programa `EBSALD01`, que processa a rotina de saldo do Emunah Bank Lab. Ele ocupa a terceira posição da cadeia batch diária:

```
EBJVALD (EBVALI01) → valida lançamentos
       ↓
EBJPOST (EBPOST01) → posta movimentos no KSDS de contas
       ↓
EBJSALD (EBSALD01) → processa/consolida saldo das contas  ← este job
       ↓
EBJEXTR (EBEXTR01) → gera extrato
       ↓
EBJCONC (EBCONC01) → conciliação
       ↓
EBJEOD  → encerramento do dia
```

O arquivo `EBJSALD.jcl` foi criado inicialmente como placeholder vazio (commit `74dd005` — 2026-03-12) durante a estruturação do repositório, e populado com o conteúdo real no commit `de2c060` (2026-03-15).

---

## 2. Estado anterior (antes da alteração)

O arquivo `jcl/batch/EBJSALD.jcl` existia no repositório mas estava **completamente vazio** — sem cartões JCL, sem DDs, sem step executável. Qualquer tentativa de submeter o job nesse estado resultaria em erro de JCL imediatamente na leitura pelo JES2.

```
Tamanho antes: 0 bytes
Conteúdo antes: (vazio)
```

---

## 3. Alteração realizada

O JCL foi implementado com o step `STEP1` executando `EBSALD01` e todos os DDs necessários para o funcionamento do programa.

### 3.1 Antes

```
(arquivo vazio)
```

### 3.2 Depois

```jcl
//* ------------------------------------------------------------
//* JOB: EBJSALD
//* FINALIDADE: Executar o programa EBSALD01 para processar a
//* rotina de saldo do laboratorio EMUNAH.
//* ------------------------------------------------------------
//EBJSALD  JOB ,'EMUNAH SALDO',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBSALD01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//SALDIN   DD DSN=Z77948.EMUNAH.ARQ.SALDO.SEQ,DISP=SHR
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
```

---

## 4. Descrição dos cartões DD implementados

| DDNAME    | Dataset                             | DISP | Finalidade |
|-----------|-------------------------------------|------|------------|
| `STEPLIB` | `Z77948.EMUNAH.DEV.LOADLIB`         | SHR  | Biblioteca com o módulo executável `EBSALD01` |
| `CONTA`   | `Z77948.EMUNAH.ARQ.CONTA.KSDS`      | SHR  | VSAM KSDS com o cadastro de contas e saldos atualizados pelo `EBPOST01` |
| `SALDIN`  | `Z77948.EMUNAH.ARQ.SALDO.SEQ`       | SHR  | Arquivo sequencial de apoio para processamento de saldo |
| `AUDIT`   | `Z77948.EMUNAH.ARQ.AUDIT.SEQ`       | MOD  | Arquivo de auditoria — `DISP=MOD` acumula registros sem sobrescrever execuções anteriores |
| `SYSOUT`  | `SYSOUT=*`                          | —    | Saída geral do step para o spool (JES2) |
| `SYSPRINT`| `SYSOUT=*`                          | —    | Saída detalhada, relatório e mensagens do programa |

### Observação sobre o DISP=MOD no AUDIT

O `DISP=MOD` no DD `AUDIT` é intencional: garante que cada execução do `EBJSALD` **acrescenta** novos registros ao arquivo de auditoria ao invés de recriá-lo. Isso é essencial em ambiente batch real, onde o `ARQ.AUDIT.SEQ` é o log histórico de todas as etapas da cadeia — sobrescrevê-lo apagaria rastreabilidade de jobs anteriores.

### Observação sobre o SALDIN

O DD `SALDIN` aponta para `ARQ.SALDO.SEQ` com `DISP=SHR`, indicado para leitura de um arquivo de apoio ou referência usada pelo `EBSALD01` na composição do saldo. O conteúdo exato e a lógica de uso desse dataset estão definidos no programa `EBSALD01` e devem ser ajustados conforme a implementação evolui.

---

## 5. Fluxo de dependência de datasets

```
EBJPOST executa primeiro
       ↓
ARQ.CONTA.KSDS (saldos atualizados)
       ↓
EBJSALD lê CONTA (KSDS) + SALDIN (SEQ)
       ↓
Grava em AUDIT (MOD) + SYSOUT/SYSPRINT
```

O `EBJSALD` deve ser submetido **somente após** o `EBJPOST` encerrar com RC ≤ 4, pois depende dos saldos já postados no `ARQ.CONTA.KSDS`.

---

## 6. Riscos e pontos de atenção

### 6.1 SALDIN ainda sem conteúdo definido

O dataset `ARQ.SALDO.SEQ` precisa existir alocado no mainframe antes da submissão do job. Se não existir, o step abenda com `IEC130I` (dataset not found). Uma alternativa temporária para testes é usar `DD DUMMY` até o programa `EBSALD01` estar completamente implementado.

### 6.2 EBSALD01 precisa estar compilado e linkeditado

O step `EXEC PGM=EBSALD01` exige que o módulo esteja na LOADLIB referenciada. Se o programa não tiver sido compilado via `EBBUILD` ou `EBCOMP`, o job terminará com `806` (program not found).

### 6.3 Ausência de COND ou RESTART

O JCL não possui cartões `COND` para proteção de steps anteriores nem `RESTART`. Em ambiente de produção real, seria necessário adicionar condição de execução baseada no RC do step anterior para evitar que `EBJSALD` rode após falha do `EBJPOST`.

---

## 7. Lições aprendidas

### 7.1 Placeholder vazio é risco de repositório

Arquivos JCL criados vazios como placeholder precisam de algum comentário mínimo (`//*`) para evitar submissão acidental. Um arquivo totalmente vazio submetido ao JES resulta em `JCL ERROR` imediato — situação que pode confundir quem está aprendendo a diagnosticar falhas.

### 7.2 Ordem importa no batch bancário

A cadeia `EBJVALD → EBJPOST → EBJSALD → EBJEXTR → EBJCONC` é sequencialmente dependente. Documentar o posicionamento de cada job na grade é parte essencial da manutenção em ambiente mainframe real.

---

## 8. Stack técnica envolvida

- **COBOL:** `EBSALD01`
- **JCL:** `EBJSALD`
- **VSAM KSDS:** `ARQ.CONTA.KSDS`
- **PS/SEQ:** `ARQ.SALDO.SEQ`, `ARQ.AUDIT.SEQ`
- **Copybooks relacionados:** `CPCNT001` (layout de conta), `CPSLD001` (layout de saldo), `CPAUD001` (layout de auditoria)
- **Zowe CLI / Zowe Explorer:** upload e submissão do JCL para o mainframe remoto

---

## 9. Evidências esperadas após submissão bem-sucedida

- RC = 0 no `STEP1`
- Mensagens de processamento no spool (`SYSOUT`)
- Novos registros acrescentados em `ARQ.AUDIT.SEQ`
- Saldos consolidados visíveis via consulta ao `ARQ.CONTA.KSDS`

---

## 10. Próximo passo recomendado

Compilar e linkeditar `EBSALD01` via `EBBUILD`, alocar `ARQ.SALDO.SEQ` caso ainda não exista, e executar a cadeia completa `EBJPOST → EBJSALD → EBJEXTR` para validar o fluxo de ponta a ponta.
