       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBSALD01.
      *===============================================================*
      * PROGRAMA: EBSALD01                                            *
      * FUNCAO : CONSULTAR E GERAR RELATORIO DE SALDOS                *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le um arquivo sequencial com contas para consulta           *
      * - Busca cada conta no arquivo KSDS de contas                  *
      * - Gera um relatorio/auditoria com o saldo encontrado          *
      * - Registra rejeicoes para contas nao encontradas              *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular uma rotina batch de consulta de saldos              *
      * - Validar se as contas existem no cadastro master             *
      * - Produzir uma saida de conferencia operacional               *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * SALDO-IN = arquivo de entrada contendo as contas a consultar  *
      *---------------------------------------------------------------*
           SELECT SALDO-IN
               ASSIGN TO SALDIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDIN.

      *---------------------------------------------------------------*
      * CONTA-KSDS = arquivo master de contas                         *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * SALDO-OUT = arquivo sequencial com resultado da consulta      *
      *---------------------------------------------------------------*
           SELECT SALDO-OUT
               ASSIGN TO SALDOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDOUT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de entrada para consulta de saldo           *
      * Cada registro informa agencia e conta                         *
      *---------------------------------------------------------------*
       FD  SALDO-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-IN-REG.
           05 SD-AGENCIA              PIC 9(4).
           05 SD-CONTA                PIC 9(8).
           05 FILLER                  PIC X(68).

      *---------------------------------------------------------------*
      * Arquivo KSDS de contas                                        *
      * O copybook CPCNT001 deve conter CNT-CHAVE e CNT-SALDO         *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de saida com saldos encontrados e rejeicoes           *
      *---------------------------------------------------------------*
       FD  SALDO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-OUT-REG               PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status dos arquivos                                      *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-SALDIN            PIC XX.
           05 WS-FS-CONTA             PIC XX.
           05 WS-FS-SALDOUT           PIC XX.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-SALDO            PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores de processamento                                   *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(5) VALUE ZERO.
           05 WS-ENCONTRADOS          PIC 9(5) VALUE ZERO.
           05 WS-NAO-ENCONTRADOS      PIC 9(5) VALUE ZERO.

      *---------------------------------------------------------------*
      * Chave montada para leitura da conta no KSDS                   *
      *---------------------------------------------------------------*
       01  WS-CHAVE-CONTA.
           05 WS-AGENCIA              PIC 9(4).
           05 WS-NUM-CONTA            PIC 9(8).

      *---------------------------------------------------------------*
      * Campo de edicao para exibir saldo formatado                   *
      *---------------------------------------------------------------*
       01  WS-SALDO-EDIT              PIC ZZZ.ZZZ.ZZ9,99.

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-CONSULTAR-SALDOS
           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos                                              *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  SALDO-IN
           OPEN INPUT  CONTA-KSDS
           OPEN OUTPUT SALDO-OUT.

      *---------------------------------------------------------------*
      * Loop de leitura do arquivo de consulta                        *
      *---------------------------------------------------------------*
       2000-CONSULTAR-SALDOS.
           PERFORM UNTIL WS-EOF-SALDO = 'S'
               READ SALDO-IN
                   AT END
                       MOVE 'S' TO WS-EOF-SALDO
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       PERFORM 2100-CONSULTAR-CONTA
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Monta a chave da conta e tenta localizar no KSDS              *
      *---------------------------------------------------------------*
       2100-CONSULTAR-CONTA.
           MOVE SD-AGENCIA TO WS-AGENCIA
           MOVE SD-CONTA   TO WS-NUM-CONTA
           MOVE WS-CHAVE-CONTA TO CNT-CHAVE OF CONTA-REG

           READ CONTA-KSDS
               INVALID KEY
                   ADD 1 TO WS-NAO-ENCONTRADOS
                   MOVE SPACES TO SALDO-OUT-REG
                   STRING 'CONTA NAO ENCONTRADA - AG '
                          SD-AGENCIA
                          ' CTA '
                          SD-CONTA
                          DELIMITED BY SIZE
                          INTO SALDO-OUT-REG
                   END-STRING
                   WRITE SALDO-OUT-REG
               NOT INVALID KEY
                   ADD 1 TO WS-ENCONTRADOS
                   MOVE CNT-SALDO OF CONTA-REG TO WS-SALDO-EDIT
                   MOVE SPACES TO SALDO-OUT-REG
                   STRING 'SALDO - AG '
                          SD-AGENCIA
                          ' CTA '
                          SD-CONTA
                          ' = '
                          WS-SALDO-EDIT
                          DELIMITED BY SIZE
                          INTO SALDO-OUT-REG
                   END-STRING
                   WRITE SALDO-OUT-REG
           END-READ.

      *---------------------------------------------------------------*
      * Exibe resumo e fecha arquivos                                 *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO CONSULTA SALDOS ***'
           DISPLAY 'CONTAS LIDAS          : ' WS-LIDOS
           DISPLAY 'CONTAS ENCONTRADAS    : ' WS-ENCONTRADOS
           DISPLAY 'CONTAS NAO ENCONTRADAS: ' WS-NAO-ENCONTRADOS

           CLOSE SALDO-IN
           CLOSE CONTA-KSDS
           CLOSE SALDO-OUT.
