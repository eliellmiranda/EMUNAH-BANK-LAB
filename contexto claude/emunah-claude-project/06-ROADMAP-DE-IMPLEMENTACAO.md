# Roadmap de Implementação do Emunah Lab

## Objetivo
Este roadmap define a ordem ideal para construir o laboratório sem perder foco.

A ordem foi pensada para maximizar:
- aderência a vagas
- realismo bancário
- realismo mainframe
- qualidade de portfólio

## Fase 1 — fundação do laboratório
Objetivo:
criar o núcleo técnico e funcional mínimo.

### Entregas
- definir entidades CLIENTE, CONTA, MOVTO, SALDO, EXTRATO e AUDIT
- definir regras funcionais mínimas
- criar padrão de nomenclatura
- criar estrutura de programas, JCLs e datasets
- documentar arquitetura inicial

### Resultado esperado
um mini core documentado e coerente.

## Fase 2 — carga inicial e cadastro
Objetivo:
construir a primeira entrega executável do laboratório.

### Entregas
- programa de carga inicial
- JCL de compile, link e execução
- massa de entrada
- saída de sucesso
- rejeito
- auditoria
- evidência técnica

### O que isso prova
- COBOL
- JCL
- arquivos
- validação
- tratamento de rejeito
- documentação

## Fase 3 — movimentação financeira
Objetivo:
implementar o coração do core mínimo.

### Entregas
- programa de depósito
- programa de saque ou transferência
- atualização de saldo
- gravação de movimento
- gravação de extrato
- gravação de auditoria
- tratamento de erro e rejeito

### O que isso prova
- regra de negócio
- coerência bancária
- atualização de posição e histórico
- desenho de processamento empresarial

## Fase 4 — fechamento do dia
Objetivo:
introduzir visão real de batch bancário.

### Entregas
- cadeia batch mínima
- consolidação de movimentos
- relatório de fechamento
- evidência de execução
- documentação do fluxo

### O que isso prova
- batch
- operações de fim de dia
- sustentação e produção
- visão de processamento corporativo

## Fase 5 — persistência ampliada
Objetivo:
fortalecer o laboratório com dados mais realistas.

### Entregas
Escolher um destes caminhos ou combinar ambos:
- DB2 para entidades principais
- VSAM para cenários de arquivo indexado

### O que isso prova
- domínio de persistência em ambiente mainframe
- aproximação com vagas reais
- evolução técnica do mini core

## Fase 6 — troubleshooting e incidentes
Objetivo:
mostrar capacidade de sustentação, não só de construção.

### Entregas
- incidentes simulados
- runbooks
- falha de RC
- falha de SQL
- falha de layout
- falha de arquivo
- causa, correção e prevenção

### O que isso prova
- sustentação
- análise de impacto
- investigação
- maturidade operacional

## Fase 7 — visão online e integração
Objetivo:
mostrar separação entre online e batch, e abrir caminho para evolução.

### Entregas
- documentação de fluxo CICS em nível conceitual ou simples
- consulta online de conta ou extrato
- documento de integração com API
- interface de entrada ou arquivo de troca

### O que isso prova
- visão transacional
- integração
- modernização sem perder o núcleo

## Fase 8 — pagamentos e contexto bancário ampliado
Objetivo:
conectar o laboratório com a realidade bancária brasileira.

### Entregas
- documento funcional de Pix no contexto do lab
- documento de Open Finance no contexto do lab
- documento de arranjos de pagamento em nível funcional
- impactos em validação, trilha, integração e segurança

### O que isso prova
- entendimento do negócio bancário
- conexão entre core e ecossistema financeiro

## Fase 9 — automação e portfólio
Objetivo:
transformar o laboratório em ativo profissional claro.

### Entregas
- scripts de apoio
- geração de evidências
- exportação de resultados
- documentação final
- README de portfólio
- estudo de caso

### O que isso prova
- autonomia
- organização
- consistência de projeto
- posicionamento profissional

## Ordem resumida
1. modelo funcional
2. carga inicial
3. movimentação
4. fechamento do dia
5. DB2 e/ou VSAM
6. incidentes e runbooks
7. online e integração
8. pagamentos
9. automação e portfólio

## Critérios de qualidade por fase
Toda fase deve produzir:
- objetivo claro
- artefatos
- evidência
- explicação funcional
- explicação técnica
- lista de riscos
- próximos passos

## O que não fazer
- tentar montar tudo ao mesmo tempo
- começar por APIs antes do core
- começar por cloud antes do batch
- acumular teoria sem artefato
- estudar ferramenta sem caso real de uso no lab

## Resultado esperado
Ao final do roadmap, o Emunah Lab deve parecer:
- um mini ambiente bancário mainframe coerente
- um laboratório de aplicações corporativas
- um portfólio técnico forte e empregável
