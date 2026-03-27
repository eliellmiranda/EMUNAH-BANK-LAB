# Mercado Mainframe Aplicado ao Emunah Lab

## Objetivo
Este documento define o que o mercado mais exige em vagas de aplicações mainframe e como isso deve ser aplicado ao laboratório.

O foco não é estudar tudo.
O foco é estudar o que mais aparece nas vagas e transformar isso em evidência prática dentro do Emunah Lab.

## Núcleo mais exigido pelo mercado
A base que mais se repete deve ser tratada como prioridade absoluta do laboratório:

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

## Camada 1 — centro técnico obrigatório
Estas competências devem aparecer claramente no laboratório:

### COBOL
Aplicação no lab:
- programa batch de carga
- programa batch de atualização
- programa de geração de extrato
- tratamento de file status
- regras de rejeição
- validação de registros
- organização empresarial de parágrafos e seções

### JCL
Aplicação no lab:
- JCL de compile
- JCL de link
- JCL de execução
- etapas com entrada, saída, rejeito e auditoria
- uso coerente de DD, DISP, RC e utilitários

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
- noção de fluxo online versus batch
- documentação de transações e programas

### VSAM e arquivos
Aplicação no lab:
- uso de sequenciais para entrada e saída
- uso de VSAM para dados persistentes ou simulação de acesso indexado
- cenários de carga, leitura, atualização e rejeito

### Batch
Aplicação no lab:
- cadeia de jobs
- processamento de fim de dia
- consolidação
- geração de relatórios
- atualização de posição
- escrita de trilha de auditoria

## Camada 2 — o que aumenta aderência a vaga real
Estas competências tornam o laboratório mais parecido com ambiente corporativo:

- troubleshooting
- incidentes simulados
- análise de impacto
- documentação de fluxo
- runbooks
- testes
- coleta de evidências
- deploy lógico
- scheduler
- changeman ou endevor em nível conceitual
- Jira / Confluence em nível de documentação
- Service Manager / ServiceNow em nível conceitual
- controle de versões com Git / GitHub

### Como provar isso no laboratório
O portfólio do Emunah Lab deve demonstrar seis capacidades:

#### 1. Desenvolver
- programa COBOL batch
- programa COBOL com DB2
- fluxo online simples ou documentado em estilo CICS

#### 2. Executar
- JCL de compile
- JCL de link
- JCL de execução
- cadeia de jobs com dependência lógica

#### 3. Testar
- massa de entrada
- saída esperada
- casos válidos e inválidos
- evidência de resultado

#### 4. Investigar
- incidente de RC
- falha de arquivo
- falha de SQL
- falha de layout
- coleta de spool
- interpretação de erro

#### 5. Documentar
- arquitetura
- fluxo funcional
- fluxo técnico
- runbook
- troubleshooting
- padrões de nomenclatura

#### 6. Automatizar
- scripts de apoio
- reset de ambiente
- submit de cadeia
- coleta de evidência
- comparação de resultados
- geração de documentação

## Camada 3 — crescimento estratégico
Estes itens não tiram o foco do núcleo, mas ajudam na evolução do perfil:

- IMS
- APIs REST
- SOAP
- JSON
- XML
- IBM Connect: Direct
- MFT
- GitHub
- Python
- scripting
- modernização de legado
- observabilidade
- pagamentos corporativos
- integração com sistemas externos

### Como aplicar sem desviar o foco
- não construir primeiro APIs complexas
- primeiro construir o núcleo batch e o mini core
- depois documentar como o core conversaria com APIs, canais, MFT e integrações
- depois adicionar um ou dois protótipos simples de integração

## Itens que não devem virar prioridade agora
- PL/I como eixo principal
- C ou C++ em mainframe como foco inicial
- cloud avançada antes do core
- DevOps avançado antes do fluxo batch e da sustentação
- RACF ou SMP/E em profundidade antes do desenvolvimento de aplicações
- excesso de ferramentas sem caso real no laboratório

## Tradução prática para backlog do lab

### Primeiro construir
- COBOL batch
- JCL
- arquivos sequenciais
- VSAM
- DB2 básico
- fluxo de saldo e movimentos
- auditoria
- extrato
- fechamento do dia

### Depois fortalecer
- troubleshooting
- incidentes simulados
- runbooks
- documentação corporativa
- testes
- scheduler
- integração conceitual com CICS

### Depois evoluir
- APIs
- pagamentos
- MFT
- modernização
- GitHub e automação
- observabilidade e suporte ampliado

## Critério de aceitação de qualquer nova funcionalidade
Uma funcionalidade nova só deve entrar se contribuir claramente para pelo menos um destes pontos:
- desenvolver aplicações mainframe
- executar aplicações mainframe
- manter aplicações mainframe
- evoluir aplicações mainframe

## Resultado esperado
Se o laboratório seguir este documento, ele deixa de parecer apenas estudo de linguagem e passa a parecer:
- ambiente de aplicações corporativas
- ambiente de sustentação e operação
- ambiente bancário realista
- portfólio alinhado com mercado
