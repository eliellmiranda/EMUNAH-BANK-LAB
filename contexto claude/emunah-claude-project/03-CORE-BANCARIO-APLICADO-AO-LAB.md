# Core Bancário Aplicado ao Emunah Lab

## Objetivo
Este documento define a visão funcional do banco que deve orientar o laboratório.

O Emunah Lab não deve ser construído como um sistema genérico de cadastro.
Ele deve representar a lógica essencial de um ambiente bancário.

## O que é core bancário no contexto do laboratório
No laboratório, core bancário significa o conjunto de dados, regras e fluxos que sustentam a operação básica da instituição.

Isso inclui:
- cliente
- conta
- saldo
- lançamentos
- extrato
- auditoria
- rejeitos
- processamento batch
- conciliação
- integração com meios de pagamento em nível funcional

## Visão macro do sistema bancário
O laboratório deve refletir que um banco não opera isoladamente.

### Camadas que precisam existir no raciocínio
- cliente e canal
- produto e conta
- processamento transacional
- posição e histórico
- batch e fechamento
- auditoria e rastreabilidade
- meios de pagamento
- liquidação e integração externa
- regulação e controles

## Conceitos que devem orientar o projeto
- evento não é a mesma coisa que posição
- movimento não é a mesma coisa que saldo
- saldo precisa ser explicado por lançamentos
- extrato depende de histórico
- auditoria precisa registrar trilha de operação
- rejeito precisa existir quando regra de negócio falha
- fechamento do dia consolida e organiza a operação
- integração com pagamentos afeta regras, validações e rastreabilidade

## Entidades mínimas do Emunah Lab

### CLIENTE
Representa a pessoa ou entidade relacionada à conta.

Campos sugeridos:
- id do cliente
- nome
- documento
- status
- data de cadastro
- canal de origem
- data de atualização

### CONTA
Representa a conta bancária ou conta de pagamento.

Campos sugeridos:
- número da conta
- agência
- id do cliente
- tipo de conta
- status
- data de abertura
- data de encerramento
- indicador de bloqueio

### MOVTO
Representa o lançamento ou evento financeiro.

Campos sugeridos:
- id do movimento
- conta
- data
- hora
- tipo de lançamento
- valor
- canal
- origem
- destino
- status
- motivo de rejeição
- identificador externo
- usuário ou processo gerador

### SALDO
Representa a posição da conta.

Campos sugeridos:
- conta
- data de posição
- saldo anterior
- débitos do período
- créditos do período
- saldo final
- data e hora de atualização

### EXTRATO
Representa a visão consultável do histórico.

Campos sugeridos:
- conta
- data
- sequência
- descrição
- valor
- natureza
- saldo após movimento
- referência do evento

### AUDIT
Representa a trilha de rastreabilidade.

Campos sugeridos:
- id de auditoria
- data e hora
- usuário ou job
- programa
- ação
- entidade afetada
- chave da entidade
- resultado
- mensagem
- origem da operação

## Fluxos mínimos prioritários

### 1. Abertura de conta
Etapas mínimas:
- validar cliente
- criar cadastro se necessário
- gerar conta
- gravar status inicial
- registrar trilha de auditoria

Saídas esperadas:
- conta ativa ou pendente
- registro de auditoria
- eventual rejeito com motivo

### 2. Depósito
Etapas mínimas:
- validar conta
- validar status
- registrar lançamento
- atualizar saldo
- gerar linha de extrato
- registrar auditoria

### 3. Saque ou transferência
Etapas mínimas:
- validar conta
- validar saldo e regras
- registrar lançamento
- atualizar saldo
- gerar extrato
- auditar
- rejeitar quando necessário

### 4. Fechamento do dia
Etapas mínimas:
- consolidar movimentos
- recalcular ou confirmar posição
- gerar saídas de controle
- gravar auditoria do processamento
- preparar dados de consulta e trilha

### 5. Consulta de extrato
Etapas mínimas:
- localizar conta
- recuperar histórico
- ordenar eventos
- devolver visão legível
- manter coerência entre extrato e saldo

## Regras funcionais mínimas
- toda alteração relevante deve gerar auditoria
- toda falha relevante deve ter motivo rastreável
- não atualizar saldo sem registrar movimento correspondente
- não gerar extrato sem base em histórico
- não aceitar operação em conta inválida ou bloqueada
- toda entrada externa precisa passar por validações mínimas
- sempre separar sucesso, rejeito e erro técnico

## Pagamentos e ecossistema bancário
O laboratório deve reconhecer em nível funcional:
- SFN
- SPB
- Pix
- Open Finance
- arranjos de pagamento
- integração com canais e sistemas externos

### Como isso deve aparecer no lab
Não é necessário reproduzir o ecossistema completo.
É necessário que o Claude entenda que:
- o banco participa de um sistema maior
- pagamentos exigem validações, rastreabilidade e integração
- liquidação, retorno, fraude, segurança e regras regulatórias importam
- o core não termina na conta; ele conversa com canais, meios de pagamento e controles

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

## Checklist funcional para qualquer fluxo novo
- qual entidade ele afeta?
- qual evento ele gera?
- qual posição ele altera?
- qual extrato ele produz?
- qual auditoria ele registra?
- qual rejeito ele pode gerar?
- qual evidência de processamento fica disponível?

## Resultado esperado
Se o laboratório seguir este documento, o projeto terá:
- coerência funcional
- cara de core bancário real
- base para batch e online
- base para documentação forte
- base para portfólio técnico e funcional
