IDENTIFICATION DIVISION.
       PROGRAM-ID. EBSALD01.
      *===============================================================*
      * PROGRAMA: EBSALD01                                            *
      * BIBLIOTECA: Z77948.EMUNAH.UTIL.COBOL                          *
      * FUNCAO : CONSULTA E RELATORIO DE SALDOS POR CONTA             *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le arquivo sequencial de entrada com pares (agencia,conta)  *
      * - Para cada par, faz READ direto (random) no KSDS de contas  *
      * - Gera saida sequencial com saldo formatado ou mensagem de    *
      *   conta nao encontrada                                        *
      * - Exibe resumo no SYSOUT ao final                             *
      *                                                               *
      * ARQUIVOS:                                                      *
      * - SALDIN  : entrada (SEQ, 80 bytes) - lista de contas         *
      * - CONTA   : master de contas (KSDS, CPCNT001)                 *
      * - SALDOUT : saida de resultado (SEQ, 120 bytes)               *
      *                                                               *
      * CODIGOS DE RETORNO:                                           *
      *   RC=0 (implicito): execucao encerrada normalmente            *
      *   Nao ha distincao entre encontradas/nao-encontradas no RC;   *
      *   o relatorio de saida evidencia os resultados.               *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * SALDIN = arquivo de entrada com contas a consultar            *
      * Cada registro de 80 bytes: agencia (4) + conta (8) + filler  *
      *---------------------------------------------------------------*
           SELECT SALDO-IN
               ASSIGN TO SALDIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDIN.

      *---------------------------------------------------------------*
      * CONTA = KSDS master de contas (ACCESS DYNAMIC para permitir   *
      * tanto leitura por chave quanto READ NEXT se necessario)       *
      * Chave primaria: CNT-CHAVE = agencia(4) + num-conta(8)         *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * SALDOUT = saida sequencial com resultado da consulta           *
      * Cada linha: texto com agencia, conta e saldo formatado        *
      * ou mensagem de conta nao encontrada                           *
      *---------------------------------------------------------------*
           SELECT SALDO-OUT
               ASSIGN TO SALDOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDOUT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de entrada                                  *
      * SD-AGENCIA  (4 bytes) : agencia a consultar                   *
      * SD-CONTA    (8 bytes) : numero de conta a consultar           *
      * FILLER      (68 bytes): reservado / nao utilizado             *
      *---------------------------------------------------------------*
       FD  SALDO-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-IN-REG.
           05 SD-AGENCIA              PIC 9(4).
           05 SD-CONTA                PIC 9(8).
           05 FILLER                  PIC X(68).

      *---------------------------------------------------------------*
      * KSDS de contas - layout definido pelo copybook CPCNT001        *
      * Campos relevantes: CNT-CHAVE, CNT-SALDO, CNT-LIMITE, CNT-STATUS*
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Saida sequencial de resultado                                 *
      * Texto livre de 120 bytes por registro                         *
      *---------------------------------------------------------------*
       FD  SALDO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-OUT-REG               PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * FILE STATUS dos tres arquivos                                 *
      * '00' = operacao OK | '10' = EOF | '23' = nao encontrado (KSDS)*
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-SALDIN            PIC XX.
           05 WS-FS-CONTA             PIC XX.
           05 WS-FS-SALDOUT           PIC XX.

      *---------------------------------------------------------------*
      * Flag de controle de fim de arquivo de entrada                 *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-SALDO            PIC X VALUE 'N'.
               88 FIM-SALDO-IN        VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores de processamento                                   *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(5) VALUE ZERO.
           05 WS-ENCONTRADOS          PIC 9(5) VALUE ZERO.
           05 WS-NAO-ENCONTRADOS      PIC 9(5) VALUE ZERO.

      *---------------------------------------------------------------*
      * Chave montada para pesquisa no KSDS                           *
      * Deve coincidir exatamente com a declaracao RECORD KEY:        *
      * WS-AGENCIA (4) || WS-NUM-CONTA (8) = 12 bytes                 *
      *---------------------------------------------------------------*
       01  WS-CHAVE-CONTA.
           05 WS-AGENCIA              PIC 9(4).
           05 WS-NUM-CONTA            PIC 9(8).

      *---------------------------------------------------------------*
      * Campo de edicao para exibir saldo com separadores             *
      * Exemplo: 1234567.89 -> ' 1.234.567,89'                        *
      *---------------------------------------------------------------*
       01  WS-SALDO-EDIT              PIC ZZZ.ZZZ.ZZ9,99.

       PROCEDURE DIVISION.
      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Orquestra abertura, processamento e encerramento              *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-CONSULTAR-SALDOS
           PERFORM 9000-ENCERRAR
           GOBACK.

      *===============================================================*
      * 1000-ABRIR-ARQUIVOS                                           *
      * SALDO-IN e CONTA-KSDS em INPUT; SALDO-OUT em OUTPUT           *
      *===============================================================*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  SALDO-IN
           OPEN INPUT  CONTA-KSDS
           OPEN OUTPUT SALDO-OUT.

      *===============================================================*
      * 2000-CONSULTAR-SALDOS                                         *
      * Loop que le cada registro de entrada e consulta o KSDS        *
      *===============================================================*
       2000-CONSULTAR-SALDOS.
           PERFORM UNTIL FIM-SALDO-IN
               READ SALDO-IN
                   AT END
                       MOVE 'S' TO WS-EOF-SALDO
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       PERFORM 2100-CONSULTAR-CONTA
               END-READ
           END-PERFORM.

      *===============================================================*
      * 2100-CONSULTAR-CONTA                                          *
      * Monta a chave composta (agencia + conta) e executa READ       *
      * random no KSDS. INVALID KEY = FS='23' = conta inexistente.   *
      * O resultado (saldo ou mensagem de nao encontrado) e gravado   *
      * no arquivo de saida SALDO-OUT.                                *
      *===============================================================*
       2100-CONSULTAR-CONTA.
      *-- Monta chave identica ao RECORD KEY declarado no SELECT ---*
           MOVE SD-AGENCIA TO WS-AGENCIA
           MOVE SD-CONTA   TO WS-NUM-CONTA
           MOVE WS-CHAVE-CONTA TO CNT-CHAVE OF CONTA-REG

           READ CONTA-KSDS
               INVALID KEY
      *-- Conta nao existe no KSDS --------------------------------*
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
      *-- Conta encontrada: edita saldo e grava resultado ---------*
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

      *===============================================================*
      * 9000-ENCERRAR                                                 *
      * Exibe resumo de contadores no SYSOUT e fecha os tres arquivos.*
      *===============================================================*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO CONSULTA SALDOS - EBSALD01 ***'
           DISPLAY 'CONTAS LIDAS          : ' WS-LIDOS
           DISPLAY 'CONTAS ENCONTRADAS    : ' WS-ENCONTRADOS
           DISPLAY 'CONTAS NAO ENCONTRADAS: ' WS-NAO-ENCONTRADOS

           CLOSE SALDO-IN
           CLOSE CONTA-KSDS
           CLOSE SALDO-OUT.