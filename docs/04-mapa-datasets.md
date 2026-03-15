Bibilotecas DEV

- EMUNAH.DEV.COBOL
- EMUNAH.DEV.COPY
- EMUNAH.DEV.JCK
- EMUNAH.DEV.REXX
- EMUNAH.DEV.LOAD

Bibliotecas HML

- EMUNAH.HML.COBOL
- EMUNAH.HML.JCL
- EMUNAH.HML.LOAD

Bibliotecas PRD simuladas

- EMUNAH.PRD.JCL
- EMUNAH.PRD.LOAD
- EMUNAH.PRD.PARMLIB

Arquivos de negócio

- EMUNAH.ARQ.CLIENTE.KSDS
- EMUNAH.ARQ.CONTA.KSDS
- EMUNHA.ARQ.LANCTO.ESDS
- EMUNAH.ARQ.SALDO.KSDS
- EMUNAH.ARQ.ENTRADA.SEQ
- EMUNAH.ARQ.REJEITO.SEQ
- EMUNAH.ARQ.AUDIT.SEQ
- EMUNAH.ARQ.EXTRATO.GDG




REFEITO PELO CHATGPT:


| Dataset                                  | Tipo        | Organização             | DDNAME esperado                                                                         | Finalidade                                                                                                        | Criado por                                         | Usado por                                                                               |
| ---------------------------------------- | ----------- | ----------------------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `Z77948.EMUNAH.DEV.COBOL`                | PDS/PDSE    | Biblioteca particionada | `SYSIN` (na compilação)                                                                 | Biblioteca de fontes COBOL de desenvolvimento                                                                     | Setup inicial / alocação manual / upload via Zowe  | Compilação (`EBCOMP`, `EBBUILD`), manutenção dos programas                              |
| `Z77948.EMUNAH.DEV.COPY`                 | PDS/PDSE    | Biblioteca particionada | `SYSLIB` (na compilação)                                                                | Biblioteca de copybooks/layouts                                                                                   | Setup inicial / alocação manual / upload via Zowe  | Compilação dos COBOLs                                                                   |
| `Z77948.EMUNAH.DEV.JCL`                  | PDS/PDSE    | Biblioteca particionada | N/A                                                                                     | Biblioteca de JCLs de desenvolvimento                                                                             | Setup inicial / alocação manual / upload via Zowe  | Submissão de jobs de compile, link e execução                                           |
| `Z77948.EMUNAH.DEV.LOADLIB`              | PDS/PDSE    | Biblioteca particionada | `SYSLMOD` (link-edit) / `STEPLIB` ou `JOBLIB` (execução)                                | Biblioteca de executáveis em DEV                                                                                  | `EBLINK` / `EBBUILD`                               | Jobs batch em DEV                                                                       |
| `Z77948.EMUNAH.DEV.REXX`                 | PDS/PDSE    | Biblioteca particionada | `SYSEXEC` ou `SYSPROC`                                                                  | Biblioteca de scripts/automação em REXX                                                                           | Setup inicial / alocação manual                    | Execução de utilitários e automações                                                    |
| `Z77948.EMUNAH.HML.COBOL`                | PDS/PDSE    | Biblioteca particionada | `SYSIN` (se houver compilação em HML)                                                   | Biblioteca de fontes para homologação                                                                             | Promoção DEV→HML / alocação manual                 | Compilação e versionamento em HML                                                       |
| `Z77948.EMUNAH.HML.JCL`                  | PDS/PDSE    | Biblioteca particionada | N/A                                                                                     | Biblioteca de JCLs de homologação                                                                                 | Promoção DEV→HML / alocação manual                 | Execução e testes em HML                                                                |
| `Z77948.EMUNAH.PRD.JCL`                  | PDS/PDSE    | Biblioteca particionada | N/A                                                                                     | Biblioteca de JCLs de produção                                                                                    | Promoção HML→PRD / alocação manual                 | Execução operacional em PRD                                                             |
| `Z77948.EMUNAH.PRD.LOADLIB`              | PDS/PDSE    | Biblioteca particionada | `STEPLIB` ou `JOBLIB`                                                                   | Biblioteca de executáveis de produção                                                                             | Promoção / link final em PRD                       | Jobs de produção                                                                        |
| `Z77948.EMUNAH.PRD.PARMLIB`              | PDS/PDSE    | Biblioteca particionada | varia (`PARM`, `SYSIN`, include de PROC etc.)                                           | Parâmetros e membros de configuração de produção                                                                  | Setup operacional / alocação manual                | JCLs e rotinas de PRD                                                                   |
| `Z77948.EMUNAH.SEED.CLIENTES.SEQ`        | PS          | Sequencial              | `CLIENTIN`                                                                              | Massa inicial de clientes                                                                                         | Upload via Zowe / seed local                       | `EBCLLOAD`                                                                              |
| `Z77948.EMUNAH.SEED.CONTAS.SEQ`          | PS          | Sequencial              | `CONTAIN`                                                                               | Massa inicial de contas                                                                                           | Upload via Zowe / seed local                       | `EBCLLOAD`                                                                              |
| `Z77948.EMUNAH.ARQ.ENTRADA.SEQ`          | PS          | Sequencial              | `ENTRADA` (validação) / `MOVTIN` (demais rotinas de movimento)                          | Entrada batch de lançamentos                                                                                      | Upload via Zowe ou geração anterior                | `EBVALI01`; possivelmente `EBPOST01`, `EBEXTR01`, `EBCONC01` se lerem direto da entrada |
| `Z77948.EMUNAH.ARQ.REJEITO.SEQ`          | PS          | Sequencial              | `REJEITOS`                                                                              | Saída de registros rejeitados                                                                                     | `EBVALI01`                                         | Conferência operacional, reprocessamento                                                |
| `Z77948.EMUNAH.ARQ.AUDIT.SEQ`            | PS          | Sequencial              | `AUDIT`                                                                                 | Trilha de auditoria, erros, duplicidades e mensagens de processamento                                             | Jobs batch que geram log                           | `EBCLLOAD`, `EBPOST01` e outras rotinas com auditoria                                   |
| `Z77948.EMUNAH.ARQ.CLIENTE.KSDS`         | VSAM        | KSDS                    | `CLIENTE`                                                                               | Cadastro master de clientes                                                                                       | Job IDCAMS de alocação + carga inicial             | `EBCLLOAD` e futuras consultas                                                          |
| `Z77948.EMUNAH.ARQ.CONTA.KSDS`           | VSAM        | KSDS                    | `CONTA`                                                                                 | Cadastro master de contas                                                                                         | Job IDCAMS de alocação + carga inicial             | `EBCLLOAD`, `EBPOST01`, `EBSALD01`                                                      |
| `Z77948.EMUNAH.ARQ.LANCTO.ESDS`          | VSAM        | ESDS                    | `VALIDOS` (se for saída da validação) / `MOVTIN` (se for entrada das rotinas seguintes) | Arquivo operacional de lançamentos; muito provavelmente guarda os movimentos aprovados ou o histórico append-only | Job IDCAMS de alocação + rotina de validação/carga | Provavelmente `EBVALI01` grava; `EBPOST01`, `EBEXTR01`, `EBCONC01` leem                 |
| `Z77948.EMUNAH.ARQ.SALDO.KSDS`           | VSAM        | KSDS                    | `SALDO`                                                                                 | Arquivo dedicado de saldos, se o desenho separar saldo do cadastro de contas                                      | Job IDCAMS de alocação + rotina de atualização     | `EBSALD01` ou outras rotinas de consulta, se o saldo ficar separado                     |
| `Z77948.EMUNAH.ARQ.EXTRATO.GDG`          | GDG Base    | Geração de datasets     | `EXTROUT`                                                                               | Base GDG para saídas históricas de extrato                                                                        | IDCAMS DEFINE GDG                                  | `EBEXTR01`                                                                              |
| `Z77948.EMUNAH.ARQ.EXTRATO.GDG.G0001V00` | GDG geração | Sequencial              | `EXTROUT`                                                                               | Primeira geração física do extrato                                                                                | `EBEXTR01` ou job de teste que gravou a geração    | Consulta, conferência e retenção histórica                                              |





Observações de uso
1. Bibliotecas de desenvolvimento

DEV.COBOL, DEV.JCL e DEV.COPY são bibliotecas de trabalho do projeto.

LOAD é a biblioteca de executáveis gerados no build.

2. Entrada e seed

SEED.CLIENTES e SEED.CONTAS servem para a carga inicial.

ENTRADA.LCTD0 representa os movimentos do lote/dia.

ENTRADA.SALDOIN existe para não deixar a rotina de saldo sem entrada definida.

3. Arquivos operacionais

KSDS.CLIENTE e KSDS.CONTA são os arquivos master do ambiente.

Eles devem ser alocados antes da execução dos jobs que os usam.

4. Saídas

SAIDA.AUDIT concentra logs e mensagens.

SAIDA.VALDOK e SAIDA.REJEIT separam os lançamentos válidos dos inválidos.

SAIDA.EXTRATO, SAIDA.CONCIL e SAIDA.SALDOS são arquivos de resultado.