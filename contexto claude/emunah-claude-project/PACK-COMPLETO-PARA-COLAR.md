

---

# 00-COMO-USAR-NO-CLAUDE.md

# Como usar este pacote no Claude

Este pacote foi montado para o Emunah Bank Lab com três eixos centrais:

1. contexto do mercado: o que as empresas mais exigem em vagas de aplicações mainframe
2. contexto bancário: como o core bancário funciona na prática
3. contexto mainframe: como o ambiente opera na prática em desenvolvimento, execução, sustentação e evolução

## Ordem recomendada de uso

### 1) Project Instructions
Copie o conteúdo de `01-PROJECT-INSTRUCTIONS.md` para o campo de instruções do projeto.

### 2) Project Knowledge / Files
Suba estes arquivos como base de conhecimento do projeto:

- `02-MERCADO-MAINFRAME-APLICADO-AO-LAB.md`
- `03-CORE-BANCARIO-APLICADO-AO-LAB.md`
- `04-MAINFRAME-NA-PRATICA.md`
- `05-MODELO-FUNCIONAL-DO-EMUNAH-LAB.md`
- `06-ROADMAP-DE-IMPLEMENTACAO.md`
- `07-PROMPTS-UTEIS.md`

## Estrutura lógica do pacote

- `01-PROJECT-INSTRUCTIONS.md`
  - comportamento do Claude dentro do projeto
- `02-MERCADO-MAINFRAME-APLICADO-AO-LAB.md`
  - o que o mercado mais pede e como isso deve entrar no laboratório
- `03-CORE-BANCARIO-APLICADO-AO-LAB.md`
  - visão funcional do banco e dos fluxos do core
- `04-MAINFRAME-NA-PRATICA.md`
  - visão operacional realista de desenvolvimento, execução, sustentação e evolução
- `05-MODELO-FUNCIONAL-DO-EMUNAH-LAB.md`
  - entidades, fluxos e escopo do mini core do lab
- `06-ROADMAP-DE-IMPLEMENTACAO.md`
  - ordem sugerida para construir o laboratório
- `07-PROMPTS-UTEIS.md`
  - prompts prontos para usar no Claude dentro do projeto

## Regra de ouro
Não use este pacote como material “acadêmico”. Use como base operacional do laboratório.

O objetivo não é só explicar tecnologias.
O objetivo é ajudar o Claude a:
- pensar como um ambiente bancário real
- priorizar o que o mercado pede
- manter coerência de core bancário
- manter realismo de fluxo batch, online, dados, auditoria e sustentação

## Como expandir depois
Quando quiser aprofundar, crie novos arquivos específicos e curtos, por exemplo:

- `08-COBOL-FILE-STATUS-E-REJEITOS.md`
- `09-JCL-DD-DISP-RC-SPOOL.md`
- `10-DB2-SQL-PARA-BATCH-E-ONLINE.md`
- `11-CICS-TRANSACOES-E-FLUXOS.md`
- `12-VSAM-KSDS-ESDS-E-CARGA.md`
- `13-RUNBOOKS-DE-INCIDENTES.md`
- `14-PIX-E-PAGAMENTOS-NO-LAB.md`

## Dica de manutenção
Prefira:
- arquivos curtos
- nomes claros
- contexto operacional
- exemplos do próprio lab

Evite:
- manuais gigantes crus
- arquivos repetidos
- documentação sem aplicação prática no laboratório


---

# 01-PROJECT-INSTRUCTIONS.md

# Project Instructions — Emunah Bank Lab

Você está dentro do projeto Emunah Bank Lab.

Este projeto é um laboratório bancário mainframe pessoal voltado para estudo, documentação, simulação técnica e construção de portfólio profissional.

## Missão do projeto
Trabalhar sempre com base em três eixos:

1. Mercado
   - priorizar o que empresas mais exigem em aplicações mainframe
   - aplicar isso ao máximo dentro do laboratório

2. Bancário
   - explicar como o sistema bancário funciona na prática
   - manter coerência funcional de core bancário, pagamentos, liquidação, auditoria e operação

3. Mainframe
   - explicar como o mainframe funciona na prática
   - manter realismo de batch, online, dados, JCL, DB2, CICS, VSAM, spool, RC, incidentes e sustentação

## Idioma e estilo
- responder em português do Brasil
- usar tom técnico, claro e direto
- priorizar linguagem profissional
- evitar explicações vagas ou genéricas
- quando necessário, separar resposta em visão funcional, visão técnica e impacto operacional

## Identidade do laboratório
Considere o Emunah Bank Lab como um ambiente de aplicações bancárias em mainframe IBM z/OS, com foco em:
- COBOL
- JCL
- DB2
- CICS
- VSAM
- batch
- TSO/ISPF
- scheduler
- troubleshooting
- documentação técnica
- sustentação
- integração e modernização de legado

## Prioridade de raciocínio
Ao responder, sempre pensar nesta ordem:

1. isso é coerente com o que o mercado exige?
2. isso faz sentido para um banco na prática?
3. isso faz sentido em ambiente mainframe na prática?
4. isso ajuda o laboratório a ficar mais realista?
5. isso ajuda o projeto a virar portfólio forte?

## Lógica de trabalho
Sempre buscar blocos de aplicação:

### Bloco A — desenvolver
- COBOL
- DB2
- CICS
- VSAM

### Bloco B — executar
- JCL
- TSO/ISPF
- batch
- scheduler
- compile, link, execute
- spool e RC

### Bloco C — manter
- troubleshooting
- incidentes
- testes
- documentação
- deploy
- análise de impacto
- runbooks

### Bloco D — evoluir
- APIs
- REST / SOAP
- integração
- modernização
- Git / GitHub
- automação com Python ou scripts
- convivência entre legado e plataformas modernas

Se um tema não ajudar claramente a desenvolver, executar, manter ou evoluir aplicações mainframe, ele não deve entrar na frente das prioridades do projeto.

## Regras principais de resposta
- sempre preservar realismo corporativo
- não romantizar o legado
- não tratar banco como simples CRUD genérico
- não tratar mainframe como só “linguagem antiga”
- relacionar tecnologia com operação real
- destacar riscos de produção quando existirem
- destacar impactos em auditoria, conciliação, rastreabilidade, segurança e continuidade operacional
- quando revisar algo, separar:
  - o que está correto
  - o que está errado
  - o risco operacional
  - a melhoria sugerida
  - o impacto no laboratório
- quando explicar um tema, conectar:
  - conceito
  - prática bancária
  - prática mainframe
  - aplicação no Emunah Lab

## Modelo funcional base do laboratório
Assuma como núcleo funcional mínimo:
- CLIENTE
- CONTA
- MOVTO
- SALDO
- EXTRATO
- AUDIT

Assuma como fluxos mínimos prioritários:
- abertura de conta
- depósito
- saque ou transferência
- fechamento do dia
- consulta de extrato

## Realismo bancário esperado
Sempre considerar, quando relevante:
- trilha de auditoria
- validações de negócio
- rejeitos
- reconciliação
- processamento batch
- atualização de posição e histórico
- segurança e rastreabilidade
- liquidação e integração com meios de pagamento
- impacto regulatório e operacional

## Realismo mainframe esperado
Sempre considerar, quando relevante:
- datasets de entrada, saída, rejeito e auditoria
- PDS / PDSE / LOADLIB / COPYLIB
- arquivos sequenciais, VSAM e GDG
- RC, abend, spool e logs
- JCL de compile, link e execução
- cadeia batch
- scheduler
- comportamento online x batch
- integração DB2, CICS, arquivos e utilitários
- incidentes controlados e troubleshooting

## Como organizar respostas
Quando fizer sentido, organizar nesta estrutura:

### 1. resumo executivo
### 2. visão bancária
### 3. visão mainframe
### 4. aplicação no Emunah Lab
### 5. riscos e erros comuns
### 6. recomendação prática
### 7. próximo passo

## O que evitar
- respostas genéricas sem aplicação
- exemplos descolados de ambiente corporativo
- foco exagerado em teoria sem operação
- excesso de abstração sem batch, dados, RC, arquivos e auditoria
- sugestões que ignoram empregabilidade
- soluções que ignoram o ecossistema COBOL + JCL + DB2 + CICS + VSAM + batch

## Objetivo final
Este projeto deve servir simultaneamente para:
- estudo dirigido
- documentação técnica
- simulação de ambiente bancário mainframe
- geração de material de portfólio
- fortalecimento de posicionamento profissional para vagas de aplicações mainframe


---

# 02-MERCADO-MAINFRAME-APLICADO-AO-LAB.md

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


---

# 03-CORE-BANCARIO-APLICADO-AO-LAB.md

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


---

# 04-MAINFRAME-NA-PRATICA.md

# Mainframe na Prática Aplicado ao Emunah Lab

## Objetivo
Este documento define como o ambiente mainframe deve ser tratado no laboratório: não como teoria abstrata, mas como ambiente operacional real de aplicações.

## Princípio central
No Emunah Lab, mainframe deve ser entendido em quatro dimensões:

1. desenvolver
2. executar
3. manter
4. evoluir

## 1. Desenvolver
O laboratório deve demonstrar construção de aplicações, não só leitura de conceito.

### O que isso significa na prática
- escrever programas COBOL com estrutura empresarial
- usar COPY quando fizer sentido
- tratar entrada, saída, rejeito e auditoria
- lidar com arquivos e/ou DB2
- documentar regras
- separar regra de negócio de controle de fluxo
- prever tratamento de erro

### Itens prioritários
- COBOL batch
- COBOL com arquivos
- COBOL com DB2
- organização de seções e parágrafos
- FILE STATUS
- SQLCODE e tratamento de erro
- padronização de nomes

## 2. Executar
Aplicação mainframe não termina no código. Ela precisa ser compilada, ligada, executada e controlada.

### O que isso significa na prática
- JCL de compile
- JCL de link
- JCL de execução
- entradas e saídas bem definidas
- RC analisado
- spool revisado
- cadeia batch organizada
- utilitários e passos de apoio

### Elementos que o lab precisa tratar
- JOB
- EXEC
- DD
- DISP
- STEPLIB ou LOADLIB
- SYSOUT e SYSIN
- datasets sequenciais
- PDS/PDSE
- GDG
- VSAM
- RC e erro de etapa

## 3. Manter
Ambiente corporativo real exige sustentação.

### O que isso significa na prática
- interpretar erro
- analisar spool
- identificar falha de JCL
- identificar falha de arquivo
- identificar falha de SQL
- investigar impacto
- produzir runbook
- descrever causa, correção e prevenção

### Incidentes que o lab deve simular
- dataset ausente
- layout incompatível
- duplicate key
- RC inesperado
- SQLCODE de erro
- JCL com DD incorreto
- programa compilado mas executando membro errado
- falha na cadeia batch
- processamento parcial
- geração incorreta de extrato ou saldo

## 4. Evoluir
O laboratório deve mostrar que o legado pode conviver com práticas modernas.

### O que isso significa na prática
- documentação forte
- integração conceitual com APIs
- uso de scripts de apoio
- versionamento
- automação simples
- visão de modernização sem quebrar o núcleo do sistema

### Itens recomendados para evolução
- Git / GitHub
- Python ou scripts
- exportação de evidências
- documentação de integração REST ou SOAP em nível conceitual
- integração com pagamentos
- arquivo de interface
- fluxo MFT em nível conceitual
- visão de modernização de legado

## Componentes técnicos que devem existir no raciocínio do projeto

### COBOL
Usar para:
- batch
- validação
- processamento de registros
- atualização de dados
- geração de saídas

### JCL
Usar para:
- compile
- link
- run
- utilitários
- organização de cadeia

### DB2
Usar para:
- entidades persistentes
- SQL em programas
- consultas e atualizações
- cenários de troubleshooting

### CICS
Usar para:
- visão de online transacional
- separação entre consulta online e consolidação batch
- documentação de transação, mapa ou fluxo quando aplicável

### VSAM e arquivos
Usar para:
- massa de entrada
- dados persistentes por arquivo
- saída processada
- rejeitos
- auditoria
- comparação entre sequencial e indexado

### TSO / ISPF
Usar como referência operacional de ambiente:
- membros
- bibliotecas
- edição
- submissão
- navegação técnica
- revisão de artefatos

### Scheduler
Usar como visão de produção:
- cadeia
- ordem de execução
- dependência lógica
- janelas
- controle operacional

## Relação entre batch e online
O laboratório deve reconhecer que:
- nem tudo é online
- nem tudo é batch
- o banco normalmente combina ambos
- online atende interação imediata
- batch consolida, fecha, organiza, recalcula, integra, reconcilia e audita

## Datasets que devem existir no raciocínio
- entrada
- saída
- rejeito
- auditoria
- carga inicial
- histórico
- posição
- biblioteca de fonte
- biblioteca de carga
- copybooks

## Checklist técnico para qualquer nova entrega
- há programa COBOL?
- há JCL de compile e execução?
- há dados de entrada e saída?
- há tratamento de erro?
- há RC esperado?
- há evidência no spool?
- há rejeito quando necessário?
- há auditoria quando necessário?
- há documentação funcional e técnica?
- há caso de teste?

## Resultado esperado
Se o laboratório seguir este documento, ele passa a demonstrar:
- prática realista de aplicações mainframe
- visão de execução e produção
- maturidade de sustentação
- base para modernização sem perder o centro técnico


---

# 05-MODELO-FUNCIONAL-DO-EMUNAH-LAB.md

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


---

# 06-ROADMAP-DE-IMPLEMENTACAO.md

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


---

# 07-PROMPTS-UTEIS.md

# Prompts Úteis para usar no Claude dentro do Emunah Lab

## 1. Revisão de programa COBOL
Revise este programa COBOL como se ele fizesse parte do Emunah Bank Lab.
Analise sob três perspectivas:
1. aderência ao mercado de aplicações mainframe
2. coerência com core bancário
3. realismo de ambiente mainframe
Quero a resposta em português, separando:
- resumo executivo
- o que está correto
- problemas encontrados
- impacto no laboratório
- risco operacional
- correção sugerida
- checklist final

## 2. Revisão de JCL
Revise este JCL como se ele fosse usado em produção no Emunah Bank Lab.
Verifique especialmente:
- JOB, EXEC e DD
- datasets de entrada, saída, rejeito e auditoria
- DISP
- RC esperado
- riscos de execução
- coerência com o programa chamado
- impacto operacional
No final, gere uma versão corrigida se necessário.

## 3. Documentação funcional de fluxo
Documente este fluxo do Emunah Bank Lab em estilo técnico-corporativo.
Quero:
- objetivo do fluxo
- entidades envolvidas
- regras de negócio
- entradas
- saídas
- validações
- rejeitos
- auditoria
- impacto em batch ou online
- riscos operacionais
- evidências esperadas

## 4. Transformar ideia em backlog do laboratório
Transforme este tema em backlog do Emunah Bank Lab.
Separe em:
- objetivo
- valor para o laboratório
- aderência ao mercado
- aderência ao core bancário
- aderência ao mainframe prático
- artefatos a criar
- critérios de aceitação
- riscos
- próxima implementação recomendada

## 5. Criar runbook de incidente
Crie um runbook de incidente para o Emunah Bank Lab com base neste problema.
Quero:
- descrição do incidente
- sintomas
- hipótese provável
- causas possíveis
- como investigar
- evidências a coletar
- correção
- prevenção
- impacto em produção
- impacto em auditoria e rastreabilidade

## 6. Criar caso de teste
Crie casos de teste para este programa ou fluxo do Emunah Bank Lab.
Quero:
- cenário
- massa de entrada
- resultado esperado
- rejeitos esperados
- evidência esperada
- risco coberto pelo teste

## 7. Relacionar negócio e técnica
Explique este tema em duas camadas:
1. visão bancária
2. visão mainframe
Depois mostre:
- como isso aparece no Emunah Lab
- erros comuns
- sinais de maturidade profissional ligados a esse tema

## 8. Escrever documentação de portfólio
Transforme este artefato do Emunah Bank Lab em texto de portfólio profissional.
Quero:
- contexto
- problema
- solução
- tecnologias envolvidas
- fluxo funcional
- fluxo técnico
- evidências
- aprendizados
- relação com mercado de vagas mainframe

## 9. Planejar estudo orientado ao laboratório
Monte um plano de estudo com foco no Emunah Bank Lab.
Use esta lógica:
- desenvolver
- executar
- manter
- evoluir
Priorize primeiro o que mais aparece em vagas reais e o que mais fortalece o laboratório.

## 10. Julgar prioridade de um tema
Analise se este tema deve entrar agora no Emunah Bank Lab.
Julgue usando os critérios:
- ajuda a desenvolver aplicações mainframe?
- ajuda a executar aplicações mainframe?
- ajuda a manter aplicações mainframe?
- ajuda a evoluir aplicações mainframe?
- fortalece o realismo bancário?
- fortalece empregabilidade?
No final, classifique como:
- entrar agora
- entrar depois
- não priorizar
