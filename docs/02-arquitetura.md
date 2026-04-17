# [02] ARQUITETURA DO LABORATÓRIO - EMUNAH BANK LAB

## Visão Geral

O laboratório é organizado em três camadas independentes que se
comunicam por meio do Zowe. Cada camada tem um papel bem definido
e não deve ser usada fora do seu escopo principal.

## Camadas

### Camada Local — Estação de Desenvolvimento
- **Ambiente:** Computador pessoal
- **Ferramentas:** VS Code, Zowe CLI, Zowe Explorer, Git
- **Responsabilidade:** edição de código-fonte, documentação,
  controle de versão e preparação de automações e cenários
- **O que reside aqui:** arquivos .cbl, .jcl, copybooks, scripts
  REXX, arquivos de massa (data/), documentação Markdown

### Camada Remota — Mainframe IBM zXplore
- **Ambiente:** IBM zXplore (z/OS compartilhado)
- **Ferramentas:** JES2, ISPF, SDSF, IDCAMS, compilador COBOL,
  link-editor
- **Responsabilidade:** armazenamento de datasets e membros,
  compilação, execução de jobs batch, manutenção dos arquivos
  de negócio
- **O que reside aqui:** bibliotecas PDS (DEV/HML/PRD), arquivos
  VSAM, GDG, sequenciais, spool de jobs

### Camada de Operação — Terminal 3270
- **Ambiente:** Emulador TN3270 (ex: IBM Personal Communications,
  Mocha TN3270 ou similar)
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
[Local: VS Code]
      |
      | upload via Zowe CLI/Explorer
      v
[Remoto: z/OS - zXplore]
      |
      | execução de jobs / operação
      v
[3270: ISPF / SDSF]
      |
      | diagnóstico / investigação
      v
[Local: análise de spool / correção]
```

## Limites e Regras

- O ambiente local é a **fonte primária** do código e da documentação
- O ambiente remoto é a **área de build e execução**
- O 3270 é a **ferramenta de operação e diagnóstico**, não de edição
- Correções permanentes devem sempre ser feitas no local e
  republicadas — não diretamente no mainframe
- Os ambientes DEV, HML e PRD simulados são separados por
  convenção de nomes de dataset, não por sistemas distintos