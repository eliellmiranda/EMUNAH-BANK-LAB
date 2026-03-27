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
