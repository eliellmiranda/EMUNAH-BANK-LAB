# Mercado Mainframe Aplicado ao Emunah Lab

## Objetivo

Este documento define o que o mercado mais exige em vagas de aplicações mainframe e como isso deve ser aplicado ao laboratório.

O foco não é estudar tudo. O foco é estudar o que mais aparece nas vagas e transformar isso em evidência prática dentro do Emunah Lab.

---

## Núcleo mais exigido pelo mercado

A base que mais se repete deve ser tratada como prioridade absoluta:

- COBOL
- JCL
- DB2
- CICS
- VSAM
- batch
- TSO/ISPF
- troubleshooting
- testes
- documentação técnica
- sustentação
- scheduler
- ferramentas de change management
- integração com sistemas modernos
- modernização de legado

---

## Camada 1 — centro técnico obrigatório

Estas competências devem aparecer claramente no laboratório.

### COBOL

Como o lab já aplica:
- `EBCLLOAD` para carga de clientes e contas
- `EBVALI01` para validação de lançamentos
- `EBPOST01` para aplicação de lançamentos
- `EBSALD01` para consolidação de saldo
- `EBEXTR01` para geração de extrato
- `EBCONC01` para conciliação
- `EBREPR01` para reprocessamento de rejeitos
- tratamento de file status, rejeição e auditoria
- organização empresarial de parágrafos e seções

### JCL

Como o lab já aplica:
- JCL de compile, link e execução (jobs `EBCOMP`, `EBLINK`, `EBBUILD`)
- cadeia batch com 10 jobs encadeados (`PRECHECK` até `EBJEOD`)
- etapas com entrada, saída, rejeito e auditoria
- uso coerente de DD, DISP, RC e utilitários
- `EBJREPR` como job sob demanda fora da cadeia

### DB2

Aplicação no lab:
- modelagem de cliente, conta, movimento, saldo e auditoria
- SQL para consulta e atualização
- programas COBOL com DB2
- cenários de erro e troubleshooting SQL

### CICS

Aplicação no lab:
- visão de online transacional
- consulta simples de conta ou extrato
- separação entre fluxo online e batch
- documentação de transações e programas

### VSAM e arquivos

Como o lab já aplica:
- KSDS para clientes (`ARQ.CLIENTE.KSDS`), contas (`ARQ.CONTA.KSDS`) e saldos (`ARQ.SALDO.KSDS`)
- ESDS para lançamentos aprovados (`ARQ.LANCTO.ESDS`)
- sequenciais para entrada (`ARQ.ENTRADA.SEQ`), rejeitos (`ARQ.REJEITO.SEQ`) e auditoria (`ARQ.AUDIT.SEQ`)
- GDG para extratos (`ARQ.EXTRATO.GDG`)
- cenários de carga, leitura, atualização e rejeito

### Batch

Como o lab já aplica:
- cadeia com 10 jobs e dependências explícitas
- janela batch simulada com horários
- processamento de fim de dia (`EBJEOD`)
- regras de bloqueio por falha
- conciliação obrigatória antes do fechamento

---

## Camada 2 — o que aumenta aderência a vaga real

Estas competências tornam o laboratório mais parecido com ambiente corporativo.

### Como o lab já demonstra

- troubleshooting com runbooks documentados para 7 tipos de incidente
- cenários de incidente controlados (`missing-input`, `invalid-layout`, `duplicate-key`, `wrong-disp`, `hold-job`, `saldo-inconsistente`, `late-file`, `reprocess-required`, `validation-rc08`)
- fluxo de promoção entre ambientes DEV → HML → PRD
- operação via Zowe CLI e Zowe Explorer
- padrões de publicação local → remoto
- documentação de módulos, datasets e grade batch

### O que ainda pode ser fortalecido

- testes formais com massa controlada e evidência estruturada
- scheduler simulado com critérios de janela
- integração conceitual com Jira/Confluence e ServiceNow
- controle de versões mais maduro com Git/GitHub
- coleta automatizada de evidências

### Seis capacidades que o portfólio deve provar

1. **Desenvolver** — programas COBOL batch, programas com DB2, fluxo online documentado
2. **Executar** — JCL de compile, link e execução, cadeia com dependência lógica
3. **Testar** — massa de entrada, saída esperada, casos válidos e inválidos, evidência
4. **Investigar** — incidente de RC, falha de arquivo, falha de SQL, falha de layout, leitura de spool
5. **Documentar** — arquitetura, fluxo funcional, fluxo técnico, runbook, troubleshooting, nomenclatura
6. **Automatizar** — scripts de apoio, reset de ambiente, submit de cadeia, coleta de evidência

---

## Camada 3 — crescimento estratégico

Estes itens não tiram o foco do núcleo, mas ajudam na evolução do perfil:

- IMS, APIs REST, SOAP, JSON, XML
- IBM Connect:Direct, MFT
- GitHub, Python, scripting
- modernização de legado
- observabilidade
- pagamentos corporativos
- integração com sistemas externos

### Como aplicar sem desviar o foco

- primeiro consolidar o núcleo batch e o mini core
- depois documentar como o core conversaria com APIs, canais, MFT e integrações
- depois adicionar protótipos simples de integração

---

## Itens que não devem virar prioridade agora

- PL/I como eixo principal
- C ou C++ em mainframe como foco inicial
- cloud avançada antes do core
- DevOps avançado antes do fluxo batch e da sustentação
- RACF ou SMP/E em profundidade antes do desenvolvimento de aplicações
- excesso de ferramentas sem caso real no laboratório

---

## Tradução prática para backlog do lab

### Primeiro consolidar
- cadeia batch completa e estável
- massa de teste coerente
- runbooks operacionais
- documentação de módulos e datasets
- fluxo Zowe consolidado

### Depois fortalecer
- DB2 integrado
- testes formais com evidência
- scheduler simulado
- cenários de incidente adicionais
- CICS conceitual ou simples

### Depois evoluir
- APIs e integração
- pagamentos
- MFT
- modernização
- automação avançada com Python ou scripts
- observabilidade e suporte ampliado

---

## Critério de aceitação de qualquer nova funcionalidade

Uma funcionalidade nova só deve entrar se contribuir claramente para pelo menos um destes pontos:
- desenvolver aplicações mainframe
- executar aplicações mainframe
- manter aplicações mainframe
- evoluir aplicações mainframe

---

## Resultado esperado

Se o laboratório seguir este documento, ele deixa de parecer estudo de linguagem e passa a parecer:
- ambiente de aplicações corporativas
- ambiente de sustentação e operação
- ambiente bancário realista
- portfólio alinhado com mercado
