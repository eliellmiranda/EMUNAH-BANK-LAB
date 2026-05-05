# [08] - FLUXO ZOWE - EMUNAH BANK LAB

## Objetivo

Este documento explica como o laboratório utiliza **Zowe CLI** e **Zowe Explorer** para conectar o projeto local ao ambiente mainframe remoto. O uso de Zowe é central no Emunah Bank Lab porque ele viabiliza um fluxo moderno de trabalho (Mainframe-as-Code) sem abandonar a dinâmica operacional e a robustez do z/OS.

---

## Princípio geral

O laboratório é organizado em uma arquitetura de três camadas interdependentes. O sucesso da operação depende do respeito ao papel de cada uma:



- **Camada Local** — Onde o código "nasce". Fontes, JCLs, Copybooks e documentação residem aqui e são versionados via Git.
- **Camada Remota** — Onde o código "trabalha". Datasets, Jobs, Spool e arquivos de negócio (VSAM/GDG) residem no z/OS.
- **Camada 3270** — Onde o código é "investigado". Terminal para troubleshooting profundo, uso de SDSF e ISPF quando a interface gráfica não for suficiente.

O **Zowe** atua como a ponte de integração, permitindo que o desenvolvedor opere o mainframe sem sair do VS Code.

---

## Papel de cada camada no fluxo

### Ambiente Local (Workstation)
- **Ferramentas:** VS Code, Zowe CLI, Git.
- **Ações:** Edição de programas COBOL, construção de JCLs, manutenção de layouts de Copybooks e scripts de automação REXX.
- **Source of Truth:** Todo arquivo nesta camada é a versão oficial e final.

### Ambiente Remoto (Mainframe zXplore)
- **Componentes:** JES2 (Jobs), PDS/PDSE (Bibliotecas), VSAM (KSDS/ESDS), GDG (Histórico).
- **Ações:** Compilação (Build), Execução Batch, Gerenciamento de Arquivos de Dados e geração de Spool.

### Ambiente 3270 (Terminal Emulation)
- **Ferramentas:** TN3270 (ISPF/SDSF).
- **Ações:** Diagnóstico de ABENDs complexos, consulta detalhada de catálogos e operação de console quando necessário.

---

## Fluxo de Trabalho Padrão (O Ciclo de Vida)

O desenvolvedor deve seguir rigorosamente esta sequência para garantir a integridade do ambiente:

1. **Editar** os arquivos localmente no VS Code.
2. **Salvar** na estrutura de pastas local do projeto (respeitando a organização por tipo).
3. **Publicar** no ambiente remoto via Zowe Explorer (drag-and-drop) ou CLI (upload).
4. **Conferir** se o membro foi gravado corretamente no PDS remoto.
5. **Submeter** o JCL de Build (`EBCOMP`) para gerar o módulo de carga (`LOADLIB`).
6. **Submeter** o JCL da cadeia batch ou utilitário.
7. **Acompanhar** o status e o Return Code (RC) no Zowe Explorer.
8. **Investigar** erros (RC > 4) através do Spool ou via SDSF no 3270.
9. **Corrigir** obrigatoriamente no local, republicar e repetir o ciclo.

---

## Fluxo de Publicação (Mapeamento)

Para que o sistema funcione, os arquivos devem ser publicados nos destinos corretos:

| Pasta Local | Dataset Remoto (PDS/SEQ) | Tipo de Artefato |
| :--- | :--- | :--- |
| `copybooks/layouts/` | `<HLQ>.EMUNAH.DEV.COPY` | Layouts de Registro |
| `cobol/batch/` | `<HLQ>.EMUNAH.DEV.COBOL` | Código-fonte COBOL |
| `jcl/batch/` | `<HLQ>.EMUNAH.DEV.JCL` | Jobs da Grade Operacional |
| `jcl/compile/` | `<HLQ>.EMUNAH.DEV.JCL` | Jobs de Compilação/Build |
| `data/normalized/` | `<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ` | Massa de Dados (Upload) |

> **Nota Técnica:** O upload de dados nunca deve ser feito diretamente no arquivo de produção (`ARQ.ENTRADA.SEQ`). O arquivo deve subir para o **STAGE**, onde o job `EBJWAIT` fará a validação de integridade antes da promoção.

---

## Fluxo de Execução e Build

O ciclo operacional mais comum envolve:
- **Build:** Submissão de `EBCOMP` (Compilação), `EBLINK` (Link-edição) e `EBBUILD` (Automação de Build).
- **Dados:** Envio da massa via Zowe CLI `files upload`.
- **Batch:** Submissão da cadeia governada pelo `ARQ.CTL.STATUS`.
- **Diagnóstico:** Download do Spool via Zowe para análise de logs de erro localmente.

---

## Regras de Ouro do Laboratório

1. **Local é Lei:** Nunca altere um código no mainframe (via ISPF 2) e esqueça de atualizar o local. O repositório Git deve refletir exatamente o que está no host.
2. **RC é Vida:** Um Job com RC 0008 ou 0012 não é um "job que rodou". É uma falha que exige investigação imediata.
3. **Edição Remota é Exceção:** Use a edição direta no Zowe Explorer apenas para testes rápidos e descartáveis. Alterações permanentes exigem o fluxo local.
4. **Respeite o Layout:** Arquivos sequenciais enviados via Zowe devem respeitar o LRECL (ex: 120 bytes para lançamentos). Use o modo binário ou ASCII conforme a necessidade do processamento COBOL.

---

## Critério de Uso Correto do Zowe

O fluxo está adequado quando o desenvolvedor consegue:
- Reinstalar todo o ambiente em um novo HLQ apenas publicando a estrutura local.
- Submeter jobs sem precisar "limpar" datasets manualmente no 3270 (automação via IDCAMS).
- Corrigir bugs de lógica em segundos, republicando apenas o membro afetado.
- Manter o histórico de alterações via commits no Git.

---

## Exemplo de Ciclo Completo

1. Alteração no cálculo de juros em `EBACCR01.cbl` (Local).
2. Upload para `<HLQ>.EMUNAH.DEV.COBOL(EBACCR01)`.
3. Submissão do JCL de compilação.
4. Verificação do Spool: `IGYCC` retornou RC 0000.
5. Submissão do Job `EBJACCR`.
6. Verificação do resultado no dataset de saída `ARQ.ACCR.MOV.SEQ`.
7. Commit das alterações no repositório local.