# [03] - MÓDULOS DO SISTEMA - EMUNAH BANK LAB

## Visão Geral

O sistema é dividido em módulos funcionais que refletem as responsabilidades de um ambiente bancário real. Cada módulo agrupa programas, copybooks e datasets relacionados a uma função específica do negócio ou do controle operacional, garantindo a separação entre o processamento transacional (Online) e o processamento de lote (Batch).

---

## 🏗️ Módulos de Infraestrutura e Controle

### controle (Máquina de Estados)
Governa a fase operacional do dia. É a "fonte de verdade" consultada por todos os jobs da cadeia principal para garantir a integridade do ciclo.

- **Programa principal:** `EBCTL01` (utilitário de validação de transição de fase)
- **Jobs que escrevem o estado:** `EBJSOD` (OPEN), `EBJCUTF` (EOTI), `EBJCUTE` (EOFI), `EBJEOD` (CLOSED)
- **Jobs que leem o estado:** `EBJPRECK` (validação de entrada da cadeia) e qualquer job que exija uma fase específica
- **Datasets:** `EMUNAH.ARQ.CTL.STATUS`, `EMUNAH.ARQ.CTL.PROCDATE`
- **Papel na cadeia:** Portão de estado — o dia não anda sem passar pelas transições na ordem estrita.

### CICS Control (Gestão de Janela)
Responsável pela transição técnica entre o ambiente transacional e o processamento batch pesado.

- **Jobs:** `EBJCLOSE` (Desconecta arquivos do CICS), `EBJOPEN` (Reconecta arquivos ao CICS)
- **Papel na cadeia:** Garante que o Batch tenha acesso exclusivo (`DISP=OLD`) aos arquivos VSAM, prevenindo erros de contenção (*Enqueue*).

---

## 🏦 Módulos de Negócio (Janela Online - CICS)

### online (Customer Service)
Simula a interface de agência e autoatendimento.

- **Transações:** - `ESLD`: Consulta de Saldo (Programa `EBCSSLD`)
  - `EEXT`: Consulta de Extrato (Programa `EBCSEXT`)
  - `ETRF`: Transferência (Programa `EBCSTRF`)
- **Telas (BMS):** `EBMSLD`, `EBMEXT`, `EBMTRF`
- **Datasets master:** `EMUNAH.ARQ.CONTA.KSDS`, `EMUNAH.ARQ.LANCTO.ESDS`
- **Papel:** Atendimento transacional em tempo real.

---

## ⚙️ Módulos de Processamento (Janela Batch)

### cliente
Cadastro e manutenção dos dados de correntistas.
- **Programa principal:** `EBCLLOAD`
- **Job de carga:** `EBJCLLD`
- **Dataset master:** `EMUNAH.ARQ.CLIENTE.KSDS` (VSAM KSDS)
- **Entrada de seed:** `EMUNAH.SEED.CLIENTES.SEQ`
- **Papel na cadeia:** Base de referência para validações de identidade.

### conta
Cadastro e gestão financeira das contas.
- **Programa principal:** `EBCLLOAD`
- **Dataset master:** `EMUNAH.ARQ.CONTA.KSDS` (VSAM KSDS)
- **Entrada de seed:** `EMUNAH.SEED.CONTAS.SEQ`
- **Papel na cadeia:** Referência obrigatória para validação, postagem e snapshot de saldo.

### entrada (staging + file-watcher)
Porta de entrada controlada para arquivos de canais externos.
- **Jobs:** `EBJWAIT` (file-watcher de existência + trailer), `EBJLOAD` (promoção para área operacional)
- **Datasets:** `EMUNAH.STAGE.ENTRADA.SEQ`, `EMUNAH.ARQ.ENTRADA.SEQ`

### lançamentos (Core Processing)
O coração financeiro do laboratório.
- **Programas:** `EBVALI01` (Validação), `EBPOST01` (Postagem/Aplicação)
- **Jobs:** `EBJVALD`, `EBJPOST`
- **Datasets:** `EMUNAH.ARQ.LANCTO.ESDS` (Válidos aprovados), `EMUNAH.ARQ.REJEITOS.SEQ`

### accrual (Contabilidade Diária)
Cálculo de juros e tarifas sobre o saldo do dia.
- **Programa principal:** `EBACCR01`
- **Entrada:** `EMUNAH.PARM.JUROS.CONFIG` (Membro de PDS com taxas)
- **Saída:** `EMUNAH.ARQ.ACCR.MOV.SEQ`
- **Papel:** Gera movimentos contábeis entre o cutoff financeiro (`EOTI`) e o snapshot.

### saldo (snapshot)
Fotografa a posição final consolidada para histórico e fechamento.
- **Programa:** `EBSNAP01` | **Job:** `EBJSNAP`
- **Dataset:** `EMUNAH.ARQ.SALDO.GDG(+1)` (Substitui o antigo saldo estático)

### conciliação
Verificação de integridade "Three-Way".
- **Programa:** `EBCONC01` | **Job:** `EBJCONC`
- **Saída:** `EMUNAH.ARQ.CONCIL.SEQ` (Relatório LRECL=132)
- **Papel:** Bloqueia o fechamento do dia se houver divergência de centavos.

### extrato
Geração do produto final para o cliente.
- **Programa:** `EBEXTR01` | **Job:** `EBJEXTR`
- **Dataset:** `EMUNAH.ARQ.EXTRATO.GDG(+1)`

### fechamento
Encerramento formal do ciclo batch.
- **Programa:** `EBJEOD01` | **Job:** `EBJEOD`
- **Efeitos:** Grava `CTL.STATUS=CLOSED`, finaliza auditoria e libera a janela para o próximo dia operacional.

---

## 🛠️ Manutenção e Recuperação

### rejeito e reprocessamento
- **Reprocessamento:** `EBREPR01` (preparação), `EBJREPR` e `EBJRPOST`.
- **Dataset:** `EMUNAH.ARQ.REPR.LANCTO.SEQ`
- **Papel:** Permite recuperar transações corrigidas sem reiniciar a cadeia do zero.

### backup
- **Job:** `EBJBCKPD`
- **Datasets:** `EMUNAH.BKP.CLIENTE.GDG`, `BKP.CONTA.GDG`, `BKP.AUDIT.GDG`
- **Papel:** Ponto de restauração (*Rollback*) em caso de falha catastrófica no batch.

### housekeeping
- **Jobs:** `EBJHKGDG`, `EBJHKAUD` (Arquiva `AUDIT.SEQ` em GDG), `EBJHKREJ`.
- **Papel:** Saneamento de ambiente e gestão de retenção de logs.

---

## 🔍 Utilitários (Manual/Ad-hoc)

Programas de apoio que **não pertencem à cadeia automática**. Executados manualmente para diagnóstico e auditoria.

### EBSALD01 — Consulta Manual de Saldo por Conta
Utilitário batch de consulta pontual ao arquivo master de contas.

**Localização:** `cobol/util/EBSALD01.cbl`

**Quando usar:**
- Conferência de saldo após aplicação de lançamentos.
- Diagnóstico de inconsistências relatadas pelo Suporte.
- Validação de registros antes de um reprocessamento.

**Arquivos envolvidos:**

| DD Name   | Dataset / Tipo            | Papel                                       |
|-----------|---------------------------|---------------------------------------------|
| `SALDIN`  | Sequencial (entrada)      | Lista de contas (Agência 4 + Conta 8)       |
| `CONTA`   | `EMUNAH.ARQ.CONTA.KSDS`   | Fonte master dos saldos                     |
| `SALDOUT` | Sequencial (saída)        | Relatório de saldos e rejeições             |

**Fluxo de execução:**
1. Abre arquivos e lê `SALDIN` sequencialmente.
2. Monta a chave composta e executa leitura direta no VSAM.
3. Grava o saldo encontrado ou o motivo da rejeição no relatório.
4. Exibe resumo de contadores no `SYSOUT`.

**Observações importantes:**
- Programa **Read-Only** (Somente leitura).
- Exige preparação prévia do arquivo de entrada `SALDIN`.
- Substitui a saída `SALDOUT` a cada execução.