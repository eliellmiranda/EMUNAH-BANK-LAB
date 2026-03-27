# Core Bancário Aplicado ao Emunah Lab

## Objetivo

Este documento define a visão funcional do banco que deve orientar o laboratório.

O Emunah Lab não é um sistema genérico de cadastro. Ele representa a lógica essencial de um ambiente bancário, com módulos, datasets e fluxos reais implementados.

---

## O que é core bancário no contexto do laboratório

Core bancário significa o conjunto de dados, regras e fluxos que sustentam a operação básica da instituição:

- cliente e conta
- saldo e lançamentos
- extrato e histórico
- auditoria e rejeitos
- processamento batch
- conciliação
- integração com meios de pagamento em nível funcional

---

## Visão macro do sistema bancário

O laboratório deve refletir que um banco não opera isoladamente.

### Camadas que existem no raciocínio

- cliente e canal
- produto e conta
- processamento transacional
- posição e histórico
- batch e fechamento
- auditoria e rastreabilidade
- meios de pagamento
- liquidação e integração externa
- regulação e controles

---

## Conceitos que orientam o projeto

- evento não é a mesma coisa que posição
- movimento não é a mesma coisa que saldo
- saldo precisa ser explicado por lançamentos
- extrato depende de histórico
- auditoria precisa registrar trilha de operação
- rejeito precisa existir quando regra de negócio falha
- fechamento do dia consolida e organiza a operação
- integração com pagamentos afeta regras, validações e rastreabilidade

---

## Entidades do Emunah Lab — implementação real

### CLIENTE
Cadastro master de pessoas ou entidades.
- **Dataset:** `Z77948.EMUNAH.ARQ.CLIENTE.KSDS` (VSAM KSDS)
- **DDNAME:** `CLIENTE`
- **Seed:** `Z77948.EMUNAH.SEED.CLIENTES.SEQ`
- **Programa de carga:** `EBCLLOAD`

Campos sugeridos: id do cliente, nome, documento, status, data de cadastro, canal de origem, data de atualização.

### CONTA
Conta bancária ou conta de pagamento.
- **Dataset:** `Z77948.EMUNAH.ARQ.CONTA.KSDS` (VSAM KSDS)
- **DDNAME:** `CONTA`
- **Seed:** `Z77948.EMUNAH.SEED.CONTAS.SEQ`
- **Programa de carga:** `EBCLLOAD`

Campos sugeridos: número da conta, agência, id do cliente, tipo de conta, status, data de abertura, data de encerramento, indicador de bloqueio.

### MOVTO (lançamentos)
Evento financeiro registrado.
- **Dataset de entrada:** `Z77948.EMUNAH.ARQ.ENTRADA.SEQ` (PS)
- **Dataset de aprovados:** `Z77948.EMUNAH.ARQ.LANCTO.ESDS` (VSAM ESDS, append-only)
- **DDNAMEs:** `ENTRADA`, `VALIDOS`
- **Programas:** `EBVALI01` (validação), `EBPOST01` (aplicação)

Campos sugeridos: id do movimento, conta, data, hora, tipo de lançamento, valor, canal, origem, destino, status, motivo de rejeição, identificador externo, usuário ou processo gerador.

### SALDO
Posição consolidada da conta.
- **Dataset:** `Z77948.EMUNAH.ARQ.SALDO.KSDS` (VSAM KSDS)
- **DDNAME:** `SALDO`
- **Programa:** `EBSALD01`

Campos sugeridos: conta, data de posição, saldo anterior, débitos do período, créditos do período, saldo final, data e hora de atualização.

### EXTRATO
Visão consultável do histórico.
- **Dataset:** `Z77948.EMUNAH.ARQ.EXTRATO.GDG` (nova geração por execução)
- **Programa:** `EBEXTR01`

Campos sugeridos: conta, data, sequência, descrição, valor, natureza, saldo após movimento, referência do evento.

### AUDIT
Trilha de rastreabilidade.
- **Dataset:** `Z77948.EMUNAH.ARQ.AUDIT.SEQ` (PS)
- **DDNAME:** `AUDIT`

Campos sugeridos: id de auditoria, data e hora, usuário ou job, programa, ação, entidade afetada, chave da entidade, resultado, mensagem, origem da operação.

### REJEITO
Registros que não passaram na validação ou aplicação.
- **Dataset:** `Z77948.EMUNAH.ARQ.REJEITO.SEQ` (PS)
- **DDNAME:** `REJEITO`
- **Gerado por:** `EBVALI01`, `EBPOST01`

---

## Fluxos implementados no laboratório

### 1. Carga inicial
- programa `EBCLLOAD` carrega clientes e contas a partir de seeds
- job `EBJLOAD` prepara o arquivo do dia
- valida layout, cria registros, rejeita inválidos, grava auditoria

### 2. Validação de lançamentos
- programa `EBVALI01` via job `EBJVALD`
- valida layout, conta válida, tipo de lançamento, valor positivo, preenchimento obrigatório
- gera arquivo de aprovados e arquivo de rejeitos

### 3. Aplicação de lançamentos
- programa `EBPOST01` via job `EBJPOST`
- aplica lançamentos válidos, atualiza contas, grava movimentos aprovados em ESDS
- trata conta bloqueada, saldo insuficiente, erros de gravação

### 4. Consolidação de saldo
- programa `EBSALD01` via job `EBJSALD`
- consolida saldos por conta após aplicação dos lançamentos

### 5. Geração de extrato
- programa `EBEXTR01` via job `EBJEXTR`
- gera nova geração de extrato em GDG

### 6. Conciliação
- programa `EBCONC01` via job `EBJCONC`
- compara totais de entrada, aplicação e saldo final
- portão de controle: o dia não fecha se a conciliação não fechar

### 7. Fechamento do dia
- job `EBJEOD`
- encerra o ciclo operacional
- depende de conciliação aprovada

### 8. Reprocessamento
- programa `EBREPR01` via job `EBJREPR`
- reaplicação de rejeitos corrigidos, fora da cadeia principal

---

## Regras funcionais mínimas

- toda alteração relevante deve gerar auditoria
- toda falha relevante deve ter motivo rastreável
- não atualizar saldo sem registrar movimento correspondente
- não gerar extrato sem base em histórico
- não aceitar operação em conta inválida ou bloqueada
- toda entrada externa precisa passar por validações mínimas
- sempre separar sucesso, rejeito e erro técnico

---

## Casos de rejeição que devem existir

- conta inexistente
- conta bloqueada
- cliente inconsistente
- valor inválido
- saldo insuficiente
- layout inválido
- duplicidade de registro
- identificador externo já processado
- data inválida
- regra de negócio não atendida

---

## Pagamentos e ecossistema bancário

O laboratório deve reconhecer em nível funcional:
- SFN, SPB
- Pix
- Open Finance
- arranjos de pagamento
- integração com canais e sistemas externos

### Como isso aparece no lab

Não é necessário reproduzir o ecossistema completo. É necessário que o Claude entenda que:
- o banco participa de um sistema maior
- pagamentos exigem validações, rastreabilidade e integração
- liquidação, retorno, fraude, segurança e regras regulatórias importam
- o core não termina na conta; ele conversa com canais, meios de pagamento e controles

---

## Checklist funcional para qualquer fluxo novo

- qual entidade ele afeta?
- qual evento ele gera?
- qual posição ele altera?
- qual extrato ele produz?
- qual auditoria ele registra?
- qual rejeito ele pode gerar?
- qual evidência de processamento fica disponível?
- qual módulo e job do lab são afetados?
- qual dataset é lido ou gravado?

---

## Resultado esperado

Se o laboratório seguir este documento, o projeto terá:
- coerência funcional com entidades e datasets reais
- cara de core bancário real
- base para batch e online
- base para documentação forte
- base para portfólio técnico e funcional
