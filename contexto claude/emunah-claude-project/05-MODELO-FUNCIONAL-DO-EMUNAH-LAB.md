# Modelo Funcional do Emunah Lab

## Objetivo
Este documento traduz mercado, core bancário e prática mainframe em um modelo mínimo e coerente para o laboratório.

## Visão do laboratório
O Emunah Lab deve simular um mini ambiente bancário mainframe com foco em:

- aplicações COBOL
- execução batch
- persistência em DB2 e/ou arquivos
- visão online simples
- trilha de auditoria
- documentação corporativa
- incidentes controlados
- portfólio profissional

## Escopo mínimo recomendado

### Entidades
- CLIENTE
- CONTA
- MOVTO
- SALDO
- EXTRATO
- AUDIT

### Fluxos
- abertura de conta
- depósito
- saque ou transferência
- fechamento do dia
- consulta de extrato

### Componentes técnicos
- programa COBOL de carga
- programa COBOL de movimentação
- programa COBOL de extrato
- programa COBOL de fechamento
- JCL de compile
- JCL de link
- JCL de execução
- datasets de entrada, saída, rejeito e auditoria
- base DB2 e/ou arquivos
- documentação funcional
- documentação técnica
- runbooks

## Arquitetura lógica sugerida

### Camada 1 — canais e entrada
Pode ser representada por:
- arquivo de entrada
- solicitação simulada
- consulta online documentada
- evento de interface

### Camada 2 — serviços de negócio
Pode ser representada por:
- validação de cliente
- validação de conta
- regras de saldo
- geração de movimentos
- geração de extrato
- registro de auditoria

### Camada 3 — persistência
Pode ser representada por:
- DB2 para entidades principais
- arquivos sequenciais para carga, saída e rejeito
- VSAM para cenários de arquivo indexado
- histórico e trilha técnica

### Camada 4 — operação batch
Pode ser representada por:
- carga inicial
- consolidação
- fechamento do dia
- relatórios
- reconciliação simples
- geração de evidências

## Programas mínimos sugeridos

### EMNCLD01 — carga inicial
Responsabilidade:
- ler massa de entrada
- validar layout
- criar clientes e contas
- rejeitar registros inválidos
- gerar auditoria

### EMNMOV01 — movimentação
Responsabilidade:
- receber evento de depósito, saque ou transferência
- validar conta e status
- validar regra de valor e saldo
- registrar movimento
- atualizar saldo
- gravar extrato
- registrar auditoria

### EMNEXT01 — extrato
Responsabilidade:
- recuperar histórico
- montar saída ordenada
- produzir visão de extrato por conta e período

### EMNCLS01 — fechamento
Responsabilidade:
- consolidar movimentos do dia
- atualizar posição
- produzir controles
- gerar evidências de fechamento

## JCLs mínimos sugeridos

### EMNJCL01 — compile
- compilação do programa COBOL
- apontamento para COPYLIB
- saída de listagem
- RC esperado documentado

### EMNJCL02 — link
- linkedição
- geração de módulo executável
- gravação em LOADLIB
- RC esperado documentado

### EMNJCL03 — carga inicial
- execução de EMNCLD01
- DDs de entrada, rejeito, auditoria e saída

### EMNJCL04 — movimentação
- execução de EMNMOV01
- DDs ou conexões com DB2
- entradas de evento e saídas de controle

### EMNJCL05 — fechamento
- execução de EMNCLS01
- relatórios, controles e auditoria

## Datasets mínimos sugeridos

### Entrada
- massa de cliente e conta
- massa de movimentos
- parâmetros

### Saída
- contas criadas
- movimentos processados
- relatórios
- extrato

### Controle
- rejeito
- auditoria
- histórico
- evidências

### Bibliotecas
- fonte COBOL
- copybooks
- loadlib
- JCL
- documentação técnica

## Regras de nomenclatura
- usar prefixo consistente
- diferenciar claramente programa, job, copybook, tabela, arquivo e relatório
- manter nomes estáveis para facilitar documentação e troubleshooting
- evitar siglas obscuras sem glossário

## Casos de teste mínimos

### Caso 1 — abertura válida
Esperado:
- cliente criado
- conta criada
- auditoria gravada

### Caso 2 — abertura inválida
Esperado:
- rejeito com motivo
- auditoria gravada
- sem conta criada

### Caso 3 — depósito válido
Esperado:
- movimento gravado
- saldo atualizado
- extrato atualizado
- auditoria gravada

### Caso 4 — saque sem saldo
Esperado:
- rejeito ou negação da operação
- saldo preservado
- auditoria gravada

### Caso 5 — fechamento do dia
Esperado:
- consolidação executada
- relatório gerado
- posição coerente
- evidência de processamento

## Evidências que o projeto deve sempre produzir
- massa de entrada
- JCL
- spool ou simulação de evidência
- saída gerada
- rejeitos
- auditoria
- explicação técnica
- explicação funcional

## Como este modelo vira portfólio
Cada entrega do laboratório deve conseguir provar:
- conhecimento técnico
- entendimento de operação bancária
- visão de produção
- capacidade de troubleshooting
- capacidade de documentação
- maturidade de raciocínio sobre legado

## Resultado esperado
Se este modelo for seguido, o Emunah Lab terá:
- escopo controlado
- coerência de domínio
- aderência ao mercado
- base forte para crescer sem perder foco
