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
