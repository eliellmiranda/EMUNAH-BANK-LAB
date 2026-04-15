       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBJEOD01.
      *===============================================================*
      * PROGRAMA : EBJEOD01                                           *
      * FUNCAO   : FECHAMENTO DIARIO (END-OF-DAY)                     *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o arquivo KSDS de contas                                 *
      * - Le o arquivo de conciliacao do dia                          *
      * - Valida se a conciliacao fechou corretamente                 *
      * - Gera relatorio de fechamento com totais consolidados        *
      * - Grava registro de auditoria com status do dia               *
      * - Marca o ciclo operacional como encerrado                    *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular o fechamento batch de um dia operacional            *
      * - Produzir evidencia de conclusao bem-sucedida do ciclo       *
      * - Identificar divergencias antes do proximo dia               *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Fechamento OK, dia encerrado com sucesso        *
      *   RC = 4  --> Fechamento com alertas (divergencias menores)   *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CONCIL-IN = arquivo de conciliacao do dia                     *
      *---------------------------------------------------------------*
           SELECT CONCIL-IN
               ASSIGN TO CONCIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONCIN.

      *---------------------------------------------------------------*
      * CONTA-KSDS = arquivo master de contas para totalizar          *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * FECHTO-OUT = relatorio de fechamento do dia                   *
      *---------------------------------------------------------------*
           SELECT FECHTO-OUT
               ASSIGN TO FECHOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-FECHOUT.

      *---------------------------------------------------------------*
      * AUDIT-OUT = registro de auditoria do fechamento               *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de conciliacao de entrada (120 bytes)                 *
      *---------------------------------------------------------------*
       FD  CONCIL-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  CONCIL-IN-REG              PIC X(120).

      *---------------------------------------------------------------*
      * Arquivo KSDS de contas                                        *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Relatorio de fechamento (132 colunas)                         *
      *---------------------------------------------------------------*
       FD  FECHTO-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  FECHTO-REG                 PIC X(132).

      *---------------------------------------------------------------*
      * Arquivo de auditoria                                          *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status                                                   *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CONCIN            PIC XX.
              88 FS-CONCIN-OK         VALUE '00'.
              88 FS-CONCIN-EOF        VALUE '10'.
           05 WS-FS-CONTA             PIC XX.
              88 FS-CONTA-OK          VALUE '00'.
              88 FS-CONTA-EOF         VALUE '10'.
           05 WS-FS-FECHOUT           PIC XX.
              88 FS-FECHOUT-OK        VALUE '00'.
           05 WS-FS-AUDIT             PIC XX.
              88 FS-AUDIT-OK          VALUE '00'.

      *---------------------------------------------------------------*
      * Controles                                                     *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-CONCIL           PIC X VALUE 'N'.
              88 EOF-CONCIL           VALUE 'S'.
           05 WS-EOF-CONTA            PIC X VALUE 'N'.
              88 EOF-CONTA            VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.
           05 WS-TEM-DIVERGENCIA      PIC X VALUE 'N'.
              88 TEM-DIVERGENCIA      VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores do fechamento                                      *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CONCIL-LIDOS         PIC 9(9) VALUE ZERO.
           05 WS-CONTAS-LIDAS         PIC 9(9) VALUE ZERO.
           05 WS-CONTAS-ATIVAS        PIC 9(9) VALUE ZERO.
           05 WS-CONTAS-INATIVAS      PIC 9(9) VALUE ZERO.
           05 WS-CONTAS-BLOQUEADAS    PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Totalizadores financeiros                                     *
      *---------------------------------------------------------------*
       01  WS-TOTAIS.
           05 WS-TOTAL-SALDOS         PIC S9(15)V99 VALUE ZERO.
           05 WS-TOTAL-LIMITES        PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Campos de edicao                                              *
      *---------------------------------------------------------------*
       01  WS-EDICAO.
           05 WS-EDIT-SALDOS          PIC -ZZZ.ZZZ.ZZZ.ZZZ.ZZ9,99.
           05 WS-EDIT-LIMITES         PIC -ZZZ.ZZZ.ZZZ.ZZZ.ZZ9,99.
           05 WS-EDIT-NUM             PIC ZZZ.ZZZ.ZZ9.

      *---------------------------------------------------------------*
      * Data e hora do fechamento                                     *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA            PIC 9(8).
       01  WS-HORA-SISTEMA            PIC 9(8).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME

           PERFORM 1000-ABRIR-ARQUIVOS

           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-LER-CONCILIACAO
               PERFORM 3000-TOTALIZAR-CONTAS
               PERFORM 4000-GERAR-RELATORIO
               PERFORM 5000-GRAVAR-AUDITORIA-FINAL
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre todos os arquivos                                        *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  CONCIL-IN
           IF NOT FS-CONCIN-OK
               DISPLAY '*** ERRO OPEN CONCIL-IN - STATUS: '
                       WS-FS-CONCIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN INPUT CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** ERRO OPEN CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT FECHTO-OUT
               IF NOT FS-FECHOUT-OK
                   DISPLAY '*** ERRO OPEN FECHTO-OUT - STATUS: '
                           WS-FS-FECHOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN EXTEND AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** ERRO OPEN AUDIT-OUT - STATUS: '
                           WS-FS-AUDIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Le o arquivo de conciliacao para confirmar que existe          *
      *---------------------------------------------------------------*
       2000-LER-CONCILIACAO.
           PERFORM UNTIL EOF-CONCIL OR OCORREU-ERRO-IO
               READ CONCIL-IN
                   AT END
                       SET EOF-CONCIL TO TRUE
                   NOT AT END
                       IF FS-CONCIN-OK
                           ADD 1 TO WS-CONCIL-LIDOS
                       ELSE
                           DISPLAY '*** ERRO READ CONCIL-IN - '
                                   WS-FS-CONCIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM

           IF WS-CONCIL-LIDOS = ZERO
               DISPLAY '*** ALERTA: CONCILIACAO VAZIA'
               SET TEM-DIVERGENCIA TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Percorre o KSDS de contas sequencialmente para totalizar      *
      *---------------------------------------------------------------*
       3000-TOTALIZAR-CONTAS.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CONTAS-LIDAS
                           ADD CNT-SALDO OF CONTA-REG
                               TO WS-TOTAL-SALDOS
                           ADD CNT-LIMITE OF CONTA-REG
                               TO WS-TOTAL-LIMITES
                           EVALUATE CNT-STATUS OF CONTA-REG
                               WHEN 'A'
                                   ADD 1 TO WS-CONTAS-ATIVAS
                               WHEN 'I'
                                   ADD 1 TO WS-CONTAS-INATIVAS
                               WHEN 'B'
                                   ADD 1 TO WS-CONTAS-BLOQUEADAS
                           END-EVALUATE
                       ELSE
                           DISPLAY '*** ERRO READ CONTA-KSDS - '
                                   WS-FS-CONTA
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Gera o relatorio de fechamento do dia                         *
      *---------------------------------------------------------------*
       4000-GERAR-RELATORIO.
           MOVE ALL '=' TO FECHTO-REG
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           STRING 'RELATORIO DE FECHAMENTO DIARIO - EMUNAH BANK LAB'
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           STRING 'DATA: ' WS-DATA-SISTEMA
                  '  HORA: ' WS-HORA-SISTEMA
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE ALL '-' TO FECHTO-REG
           WRITE FECHTO-REG

           MOVE WS-CONTAS-LIDAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL DE CONTAS NO CADASTRO   : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONTAS-ATIVAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING '  CONTAS ATIVAS               : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONTAS-INATIVAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING '  CONTAS INATIVAS             : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONTAS-BLOQUEADAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING '  CONTAS BLOQUEADAS           : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE ALL '-' TO FECHTO-REG
           WRITE FECHTO-REG

           MOVE WS-TOTAL-SALDOS TO WS-EDIT-SALDOS
           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL GERAL DE SALDOS         : '
                  WS-EDIT-SALDOS
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-TOTAL-LIMITES TO WS-EDIT-LIMITES
           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL GERAL DE LIMITES        : '
                  WS-EDIT-LIMITES
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONCIL-LIDOS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING 'REGISTROS DE CONCILIACAO       : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE
                  INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE ALL '-' TO FECHTO-REG
           WRITE FECHTO-REG

           IF TEM-DIVERGENCIA
               MOVE SPACES TO FECHTO-REG
               STRING '*** ALERTA: DIVERGENCIAS DETECTADAS ***'
                      DELIMITED BY SIZE
                      INTO FECHTO-REG
               END-STRING
               WRITE FECHTO-REG
           ELSE
               MOVE SPACES TO FECHTO-REG
               STRING 'FECHAMENTO CONCLUIDO COM SUCESSO'
                      DELIMITED BY SIZE
                      INTO FECHTO-REG
               END-STRING
               WRITE FECHTO-REG
           END-IF

           MOVE ALL '=' TO FECHTO-REG
           WRITE FECHTO-REG.

      *---------------------------------------------------------------*
      * Grava registro final de auditoria                             *
      *---------------------------------------------------------------*
       5000-GRAVAR-AUDITORIA-FINAL.
           MOVE SPACES TO AUDIT-REG

           IF TEM-DIVERGENCIA
               STRING 'EOD FECHAMENTO COM ALERTAS - DATA '
                      WS-DATA-SISTEMA
                      ' HORA '
                      WS-HORA-SISTEMA
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
           ELSE
               STRING 'EOD FECHAMENTO OK - DATA '
                      WS-DATA-SISTEMA
                      ' HORA '
                      WS-HORA-SISTEMA
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
           END-IF

           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** ERRO WRITE AUDIT - STATUS: '
                       WS-FS-AUDIT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Fecha todos os arquivos                                       *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           CLOSE CONCIL-IN
           CLOSE CONTA-KSDS
           CLOSE FECHTO-OUT
           CLOSE AUDIT-OUT.

      *---------------------------------------------------------------*
      * Exibe resumo e define RETURN-CODE                             *
      *---------------------------------------------------------------*
       9100-DEFINIR-RETURN-CODE.
           DISPLAY '*** RESUMO FECHAMENTO DIARIO ***'
           DISPLAY 'REGISTROS CONCILIACAO  : ' WS-CONCIL-LIDOS
           DISPLAY 'CONTAS NO CADASTRO     : ' WS-CONTAS-LIDAS
           DISPLAY 'CONTAS ATIVAS          : ' WS-CONTAS-ATIVAS
           DISPLAY 'CONTAS INATIVAS        : ' WS-CONTAS-INATIVAS
           DISPLAY 'CONTAS BLOQUEADAS      : ' WS-CONTAS-BLOQUEADAS

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN TEM-DIVERGENCIA
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
