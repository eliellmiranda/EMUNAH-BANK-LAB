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


| Dataset                         | Tipo      | Organização             | Finalidade                                                                  | Criado por                                   | Usado por                                                 |
| ------------------------------- | --------- | ----------------------- | --------------------------------------------------------------------------- | -------------------------------------------- | --------------------------------------------------------- |
| `Z77948.EMUNAH.DEV.COBOL`       | PDS/PDSE  | Biblioteca particionada | Armazenar os fontes COBOL batch do laboratório                              | Usuário / Zowe / ISPF                        | `EBCOMP`, `EBBUILD`, manutenção dos fontes                |
| `Z77948.EMUNAH.DEV.JCL`         | PDS/PDSE  | Biblioteca particionada | Armazenar os JCLs de compilação, link e execução batch                      | Usuário / Zowe / ISPF                        | Submissão de jobs batch                                   |
| `Z77948.EMUNAH.DEV.COPY`        | PDS/PDSE  | Biblioteca particionada | Armazenar os copybooks/layouts reutilizáveis                                | Usuário / Zowe / ISPF                        | Compilação dos programas COBOL                            |
| `Z77948.EMUNAH.LOAD`            | PDS/PDSE  | Biblioteca particionada | Armazenar os load modules gerados após compilação e link-edição             | `EBLINK` / `EBBUILD`                         | `EBJLOAD`, `EBJVALD`, `EBJPOST` e demais jobs de execução |
| `Z77948.EMUNAH.SEED.CLIENTES`   | PS        | Sequencial              | Massa inicial de clientes para carga do ambiente                            | Usuário / upload via Zowe                    | `EBCLLOAD`                                                |
| `Z77948.EMUNAH.SEED.CONTAS`     | PS        | Sequencial              | Massa inicial de contas para carga do ambiente                              | Usuário / upload via Zowe                    | `EBCLLOAD`                                                |
| `Z77948.EMUNAH.ENTRADA.LCTD0`   | PS        | Sequencial              | Arquivo de lançamentos do dia 0, usado como entrada batch                   | Usuário / upload via Zowe                    | `EBVALI01`, `EBPOST01`, `EBEXTR01`, `EBCONC01`            |
| `Z77948.EMUNAH.ENTRADA.SALDOIN` | PS        | Sequencial              | Lista de contas para consulta de saldo                                      | Usuário / upload via Zowe                    | `EBSALD01`                                                |
| `Z77948.EMUNAH.KSDS.CLIENTE`    | VSAM KSDS | Indexado                | Cadastro operacional de clientes                                            | Job de alocação VSAM / administração inicial | `EBCLLOAD`, futuras consultas/rotinas                     |
| `Z77948.EMUNAH.KSDS.CONTA`      | VSAM KSDS | Indexado                | Cadastro operacional de contas e saldos                                     | Job de alocação VSAM / administração inicial | `EBCLLOAD`, `EBPOST01`, `EBSALD01`                        |
| `Z77948.EMUNAH.SAIDA.AUDIT`     | PS        | Sequencial              | Registro de auditoria, mensagens de processamento, rejeições e duplicidades | Job que grava a saída / pode ser pré-alocado | `EBCLLOAD`, `EBPOST01` e outras rotinas com log           |
| `Z77948.EMUNAH.SAIDA.VALDOK`    | PS        | Sequencial              | Saída com lançamentos aprovados na validação                                | `EBJVALD` / `EBVALI01`                       | Fluxos posteriores de processamento                       |
| `Z77948.EMUNAH.SAIDA.REJEIT`    | PS        | Sequencial              | Saída com lançamentos rejeitados e motivo do erro                           | `EBJVALD` / `EBVALI01`                       | Conferência operacional e reprocessamento                 |
| `Z77948.EMUNAH.SAIDA.EXTRATO`   | PS        | Sequencial              | Relatório/arquivo de extrato gerado a partir dos lançamentos                | `EBEXTR01`                                   | Conferência, testes e saída operacional                   |
| `Z77948.EMUNAH.SAIDA.CONCIL`    | PS        | Sequencial              | Resultado da conciliação dos lançamentos                                    | `EBCONC01`                                   | Conferência operacional                                   |
| `Z77948.EMUNAH.SAIDA.SALDOS`    | PS        | Sequencial              | Resultado das consultas de saldo                                            | `EBSALD01`                                   | Conferência operacional                                   |




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