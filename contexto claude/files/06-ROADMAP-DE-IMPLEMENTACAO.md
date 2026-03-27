# Roadmap de Implementação do Emunah Lab

## Objetivo

Este roadmap define a ordem ideal para construir o laboratório sem perder foco, com critérios de conclusão por fase.

A ordem foi pensada para maximizar:
- aderência a vagas
- realismo bancário
- realismo mainframe
- qualidade de portfólio

---

## Fase 1 — fundação do laboratório

**Objetivo:** criar o núcleo técnico e funcional mínimo.

**Entregas:**
- definir entidades: CLIENTE, CONTA, MOVTO, SALDO, EXTRATO, AUDIT
- definir regras funcionais mínimas
- criar padrão de nomenclatura (prefixo EB, convenção de datasets)
- criar estrutura de programas, JCLs e datasets
- documentar arquitetura inicial (três camadas)

**Critério de conclusão:** existe um documento de modelo funcional com entidades, módulos, mapa de datasets e convenção de nomenclatura.

---

## Fase 2 — carga inicial e cadastro

**Objetivo:** construir a primeira entrega executável do laboratório.

**Entregas:**
- programa de carga inicial (`EBCLLOAD`)
- JCL de compile, link e execução
- massa de entrada (seeds de clientes e contas)
- saída de sucesso (KSDS populados)
- rejeito e auditoria
- evidência técnica (spool, RC)

**O que isso prova:** COBOL, JCL, arquivos, validação, tratamento de rejeito, documentação.

**Critério de conclusão:** o programa compila, executa via JCL, popula os KSDS de clientes e contas, gera rejeitos quando a massa tem erros e produz trilha de auditoria.

---

## Fase 3 — movimentação financeira

**Objetivo:** implementar o coração do core mínimo.

**Entregas:**
- programa de validação (`EBVALI01`)
- programa de aplicação (`EBPOST01`)
- atualização de saldo
- gravação de movimento em ESDS
- gravação de extrato
- gravação de auditoria
- tratamento de erro e rejeito

**O que isso prova:** regra de negócio, coerência bancária, atualização de posição e histórico, desenho de processamento empresarial.

**Critério de conclusão:** os jobs `EBJVALD` e `EBJPOST` executam com sucesso para lançamentos válidos, rejeitam lançamentos inválidos com motivo documentado e atualizam contas, saldos e auditoria.

---

## Fase 4 — fechamento do dia

**Objetivo:** introduzir visão real de batch bancário.

**Entregas:**
- cadeia batch completa (`PRECHECK` até `EBJEOD`)
- consolidação de saldo (`EBSALD01`)
- geração de extrato (`EBEXTR01`)
- conciliação (`EBCONC01`)
- fechamento (`EBJEOD`)
- documentação da grade batch

**O que isso prova:** batch, operações de fim de dia, sustentação e produção, visão de processamento corporativo.

**Critério de conclusão:** a cadeia batch inteira executa do PRECHECK ao EBJEOD sem intervenção manual, a conciliação fecha corretamente e o extrato GDG é gerado.

---

## Fase 5 — persistência ampliada

**Objetivo:** fortalecer o laboratório com dados mais realistas.

**Entregas:**
- VSAM KSDS para clientes, contas e saldos (já implementado)
- VSAM ESDS para lançamentos aprovados (já implementado)
- GDG para extratos (já implementado)
- DB2 para entidades principais (evolução)

**O que isso prova:** domínio de persistência em ambiente mainframe, aproximação com vagas reais, evolução técnica.

**Critério de conclusão:** pelo menos um programa utiliza DB2 para consulta ou atualização, com tratamento de SQLCODE, e os arquivos VSAM e GDG estão operacionais e integrados à cadeia.

---

## Fase 6 — troubleshooting e incidentes

**Objetivo:** mostrar capacidade de sustentação, não só de construção.

**Entregas:**
- runbooks operacionais (7 incidentes documentados)
- cenários de incidente controlados (10 cenários)
- programa de reprocessamento (`EBREPR01`)
- job de reprocessamento (`EBJREPR`)
- documentação de causa, correção e prevenção

**O que isso prova:** sustentação, análise de impacto, investigação, maturidade operacional.

**Critério de conclusão:** cada cenário pode ser reproduzido no ambiente, diagnosticado com o runbook correspondente e resolvido com a ação corretiva documentada.

---

## Fase 7 — visão online e integração

**Objetivo:** mostrar separação entre online e batch e abrir caminho para evolução.

**Entregas:**
- documentação de fluxo CICS em nível conceitual ou simples
- consulta online de conta ou extrato
- documento de integração com API
- interface de entrada ou arquivo de troca

**O que isso prova:** visão transacional, integração, modernização sem perder o núcleo.

**Critério de conclusão:** existe documentação funcional e técnica de pelo menos um fluxo online, com separação clara entre o que é online e o que é batch.

---

## Fase 8 — pagamentos e contexto bancário ampliado

**Objetivo:** conectar o laboratório com a realidade bancária brasileira.

**Entregas:**
- documento funcional de Pix no contexto do lab
- documento de Open Finance no contexto do lab
- documento de arranjos de pagamento em nível funcional
- impactos em validação, trilha, integração e segurança

**O que isso prova:** entendimento do negócio bancário, conexão entre core e ecossistema financeiro.

**Critério de conclusão:** existe documentação que descreve como pelo menos um meio de pagamento (Pix) interage com os módulos e datasets do lab.

---

## Fase 9 — automação e portfólio

**Objetivo:** transformar o laboratório em ativo profissional claro.

**Entregas:**
- scripts de apoio (REXX, shell, Python)
- geração automatizada de evidências
- exportação de resultados
- documentação final
- README de portfólio
- estudo de caso

**O que isso prova:** autonomia, organização, consistência de projeto, posicionamento profissional.

**Critério de conclusão:** o repositório possui README, documentação completa, scripts funcionais e pelo menos um estudo de caso descrevendo problema, solução e evidências.

---

## Ordem resumida

1. modelo funcional
2. carga inicial
3. movimentação
4. fechamento do dia
5. DB2 e/ou VSAM ampliado
6. incidentes e runbooks
7. online e integração
8. pagamentos
9. automação e portfólio

---

## Critérios de qualidade por fase

Toda fase deve produzir:
- objetivo claro
- artefatos entregues
- evidência de execução
- explicação funcional
- explicação técnica
- lista de riscos
- próximos passos
- critério de conclusão atendido

---

## O que não fazer

- tentar montar tudo ao mesmo tempo
- começar por APIs antes do core
- começar por cloud antes do batch
- acumular teoria sem artefato
- estudar ferramenta sem caso real de uso no lab
- pular fases antes de atender os critérios de conclusão

---

## Resultado esperado

Ao final do roadmap, o Emunah Lab deve parecer:
- um mini ambiente bancário mainframe coerente
- um laboratório de aplicações corporativas com módulos reais
- um portfólio técnico forte e empregável
