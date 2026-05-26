# [02] - ARQUITETURA DO LABORATÓRIO - EMUNAH BANK LAB

## Visão Geral

O laboratório é organizado em três camadas independentes que se comunicam por meio do Zowe. Cada camada tem um papel bem definido e não deve ser usada fora do seu escopo principal.

A camada remota armazena os datasets separados em categorias funcionais — `ARQ` (operacionais do dia), `BKP` (backups versionados em GDG), `STAGE` (staging antes de `ARQ`), `PARM` (parâmetros), `SEED` (carga inicial), e `DEV`/`HML`/`PRD` (bibliotecas por ambiente). Esta separação espelha a prática bancária real de isolar arquivos transacionais de backups, histórico e configuração.

## Camadas

### Camada Local — Estação de Desenvolvimento
- **Ambiente:** Computador pessoal
- **Ferramentas:** VS Code, Zowe CLI, Zowe Explorer, Git, Python (EBOPS)
- **Responsabilidade:** edição de código-fonte, documentação,
  controle de versão, preparação de automações e cenários,
  e injeção de incidentes simulados via EBOPS
- **O que reside aqui:** arquivos .cbl, .jcl, copybooks, scripts
  REXX, arquivos de massa, documentação Markdown, scripts Python
  do simulador operacional (EBOPS)

> **EBOPS — Emunah Bank Operations Simulator:** componente Python
> que simula o lado "humano" e caótico de um dia operacional bancário.
> Injeta incidentes reais (mutações de código, corrupção de JCL,
> dados truncados) e emula ferramentas corporativas como Control-M,
> Jira e Fault Analyzer, criando pressão de cenário *live* para
> a prática de troubleshooting.

### Camada Remota — Mainframe IBM zXplore
- **Ambiente:** IBM zXplore (z/OS compartilhado)
- **Ferramentas:** VS Code, JES2, IDCAMS, compilador COBOL,
  link-editor, CICS TS, DB2
- **Responsabilidade:** armazenamento de datasets e membros,
  compilação, execução de jobs batch, manutenção dos arquivos
  de negócio, processamento transacional online (CICS) e
  persistência relacional (DB2)
- **O que reside aqui:** bibliotecas PDS (DEV/HML/PRD), arquivos
  VSAM (KSDS/ESDS), GDG, sequenciais, spool de jobs,
  tabelas DB2, regiões CICS

### Camada de Operação — Terminal 3270
- **Ambiente:** Emulador TN3270
- **Ferramentas:** ISPF, SDSF, TSO, IDCAMS interativo
- **Responsabilidade:** operação clássica, troubleshooting
  aprofundado, análise de spool, consulta a datasets e
  investigação de abends
- **Quando usar:** sempre que o Zowe Explorer não for suficiente
  para diagnóstico ou operação

## Ponte entre camadas — Zowe

O Zowe atua como a integração entre o ambiente local e o mainframe:

| Ação                              | Ferramenta         |
|-----------------------------------|--------------------|
| Publicar fonte/JCL no mainframe   | Zowe CLI / Explorer|
| Abrir membro remoto no VS Code    | Zowe Explorer      |
| Submeter job                      | Zowe CLI / Explorer|
| Consultar status e RC do job      | Zowe CLI / Explorer|
| Baixar spool para análise local   | Zowe CLI           |
| Enviar arquivo de entrada (SEQ)   | Zowe CLI           |

## Fluxo Resumido
```
[EBOPS — Simulador Python]
      |
      | injeta incidentes / sorteia cenários
      v
[Local: VS Code + Git]
      |
      | upload via Zowe CLI/Explorer
      v
[Remoto: z/OS - zXplore]
   |          |
   |          | CICS (Online) / DB2
   |          v
   |    [Transações em tempo real]
   |
   | execução de jobs batch
   v
[3270: ISPF / SDSF]
      |
      | diagnóstico / investigação de abends
      v
[Local: análise de spool / correção / commit]
      |
      | (loop: nova correção republica via Zowe)
      v
[Remoto: z/OS - recompilação e re-execução]
```

## Limites e Regras

- O ambiente local é a **fonte primária** do código e da documentação
- O ambiente remoto é a **área de build e execução**
- O 3270 é a **ferramenta de operação e diagnóstico**, não de edição
- Correções permanentes devem sempre ser feitas no local e
  republicadas — não diretamente no mainframe
- Os ambientes DEV, HML e PRD simulados são separados por
  convenção de nomes de dataset, não por sistemas distintos
