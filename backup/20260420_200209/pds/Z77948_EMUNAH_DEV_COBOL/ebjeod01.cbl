       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBJEOD01.
      *===============================================================*
      * PROGRAMA : EBJEOD01                                           *
      * FUNCAO   : FECHAMENTO DIARIO (END-OF-DAY)                     *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o arquivo de conciliacao e detecta marcadores de         *
      *   divergencia gravados pelo EBCONC01 ([DIVERGENCIA])          *
      * - Le o snapshot GDG do dia (SALDOIN) para totalizar saldo     *
      * - Percorre o KSDS de contas para totalizar posicao final      *
      * - Gera relatorio de fechamento com evidencias do dia          *
      * - Grava registro de auditoria com status do fechamento        *
      *                                                               *
      * O STATUS do branch (CLOSED) e gravado pelo step CLOSDAY       *
      * do EBJEOD.jcl via IEBGENER apos este programa terminar RC=0. *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Fechamento OK, dia encerrado com sucesso        *
      *   RC = 4  --> Fechamento com alertas (divergencias menores)   *
      *   RC = 8  --> Erro critico de I/O                             *
      *                                                               *
      * REVISOES:                                                     *
      * - 2000-LER-CONCILIACAO: detecta [DIVERGENCIA] via             *
      *   FUNCTION INDEX (layout estruturado do EBCONC01)             *
      * - 6000-LER-SALDO-GDG: le ARQ.SALDO.GDG(0) para relatorio     *
      * - 9000-FECHAR-ARQUIVOS: FILE STATUS verificado em todos CLOSE *
      * - Relatorio inclui total saldo GDG e alerta de divergencia    *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CONCIL-IN = arquivo de conciliacao do dia (CONCIL.SEQ)        *
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

      *---------------------------------------------------------------*
      * SALDO-IN = snapshot GDG do dia (ARQ.SALDO.GDG(0)) - opcional  *
      *---------------------------------------------------------------*
           SELECT SALDO-IN
               ASSIGN TO SALDOIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de conciliacao (120 bytes)                            *
      * Layout estruturado gravado pelo EBCONC01:                     *
      *   linhas com marcadores [PASSOU] ou [DIVERGENCIA]             *
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
      * Arquivo de auditoria (DISP=MOD no JCL)                        *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

      *---------------------------------------------------------------*
      * Snapshot de saldo GDG (120 bytes - layout EBSNAP01)           *
      * SLD-AGENCIA(4) SLD-CONTA(8) SLD-SALDO S9(11)V99(13)          *
      * SLD-DATA(8) FILLER(87)                                        *
      *---------------------------------------------------------------*
       FD  SALDO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-IN-REG.
           05 SLD-AGENCIA             PIC X(4).
           05 SLD-CONTA               PIC X(8).
           05 SLD-SALDO               PIC S9(11)V99.
           05 SLD-DATA                PIC X(8).
           05 FILLER                  PIC X(87).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status                                                   *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CONCIN            PIC XX VALUE SPACES.
              88 FS-CONCIN-OK         VALUE '00'.
              88 FS-CONCIN-EOF        VALUE '10'.
           05 WS-FS-CONTA             PIC XX VALUE SPACES.
              88 FS-CONTA-OK          VALUE '00'.
              88 FS-CONTA-EOF         VALUE '10'.
           05 WS-FS-FECHOUT           PIC XX VALUE SPACES.
              88 FS-FECHOUT-OK        VALUE '00'.
           05 WS-FS-AUDIT             PIC XX VALUE SPACES.
              88 FS-AUDIT-OK          VALUE '00'.
           05 WS-FS-SALDO             PIC XX VALUE SPACES.
              88 FS-SALDO-OK          VALUE '00'.
              88 FS-SALDO-EOF         VALUE '10'.

      *---------------------------------------------------------------*
      * Controles de EOF e flags                                      *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-CONCIL           PIC X VALUE 'N'.
              88 EOF-CONCIL           VALUE 'S'.
           05 WS-EOF-CONTA            PIC X VALUE 'N'.
              88 EOF-CONTA            VALUE 'S'.
           05 WS-EOF-SALDO            PIC X VALUE 'N'.
              88 EOF-SALDO            VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.
           05 WS-TEM-DIVERGENCIA      PIC X VALUE 'N'.
              88 TEM-DIVERGENCIA      VALUE 'S'.
              88 SEM-DIVERGENCIA      VALUE 'N'.
           05 WS-CONCIL-DIVERGENTE    PIC X VALUE 'N'.
              88 CONCIL-DIVERGENTE    VALUE 'S'.
           05 WS-SALDO-DISP           PIC X VALUE 'N'.
              88 SALDO-DISPONIVEL     VALUE 'S'.
              88 SALDO-INDISPONIVEL   VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ABERTOS.
           05 WS-CONCIN-ABERTO        PIC X VALUE 'N'.
              88 CONCIN-ABERTO        VALUE 'S'.
           05 WS-CONTA-ABERTO         PIC X VALUE 'N'.
              88 CONTA-ABERTO         VALUE 'S'.
           05 WS-FECHOUT-ABERTO       PIC X VALUE 'N'.
              88 FECHOUT-ABERTO       VALUE 'S'.
           05 WS-AUDIT-ABERTO         PIC X VALUE 'N'.
              88 AUDIT-ABERTO         VALUE 'S'.

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
           05 WS-SOMA-SALDO-GDG       PIC S9(15)V99 VALUE ZERO.

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
               PERFORM 6000-LER-SALDO-GDG
               PERFORM 4000-GERAR-RELATORIO
               PERFORM 5000-GRAVAR-AUDITORIA-FINAL
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre todos os arquivos com verificacao de FILE STATUS         *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT CONCIL-IN
           IF FS-CONCIN-OK
               SET CONCIN-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN CONCIL-IN - STATUS: '
                       WS-FS-CONCIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN INPUT CONTA-KSDS
               IF FS-CONTA-OK
                   SET CONTA-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT FECHTO-OUT
               IF FS-FECHOUT-OK
                   SET FECHOUT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN FECHTO-OUT - STATUS: '
                           WS-FS-FECHOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN EXTEND AUDIT-OUT
               IF FS-AUDIT-OK
                   SET AUDIT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN AUDIT-OUT - STATUS: '
                           WS-FS-AUDIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Le CONCIL.SEQ e detecta marcadores [DIVERGENCIA]              *
      * gravados pelo EBCONC01 redesenhado                            *
      *---------------------------------------------------------------*
       2000-LER-CONCILIACAO.
           PERFORM UNTIL EOF-CONCIL OR OCORREU-ERRO-IO
               READ CONCIL-IN
                   AT END
                       SET EOF-CONCIL TO TRUE
                   NOT AT END
                       IF FS-CONCIN-OK
                           ADD 1 TO WS-CONCIL-LIDOS
                           IF FUNCTION INDEX(CONCIL-IN-REG,
                                            '[DIVERGENCIA]') > 0
                               SET TEM-DIVERGENCIA   TO TRUE
                               SET CONCIL-DIVERGENTE TO TRUE
                           END-IF
                       ELSE
                           DISPLAY '*** ERRO READ CONCIL-IN - '
                                   WS-FS-CONCIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM

           IF WS-CONCIL-LIDOS = ZERO
               DISPLAY '*** ALERTA: CONCIL.SEQ VAZIA'
               SET TEM-DIVERGENCIA TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Percorre KSDS de contas para totalizar posicao final          *
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
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           STRING 'DATA: ' WS-DATA-SISTEMA
                  '  HORA: ' WS-HORA-SISTEMA
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE ALL '-' TO FECHTO-REG
           WRITE FECHTO-REG

           MOVE WS-CONTAS-LIDAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL DE CONTAS NO CADASTRO   : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONTAS-ATIVAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING '  CONTAS ATIVAS               : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONTAS-INATIVAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING '  CONTAS INATIVAS             : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-CONTAS-BLOQUEADAS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING '  CONTAS BLOQUEADAS           : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE ALL '-' TO FECHTO-REG
           WRITE FECHTO-REG

           MOVE WS-TOTAL-SALDOS TO WS-EDIT-SALDOS
           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL GERAL DE SALDOS (KSDS)  : '
                  WS-EDIT-SALDOS
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE WS-TOTAL-LIMITES TO WS-EDIT-LIMITES
           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL GERAL DE LIMITES        : '
                  WS-EDIT-LIMITES
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           IF SALDO-DISPONIVEL
               MOVE WS-SOMA-SALDO-GDG TO WS-EDIT-SALDOS
               MOVE SPACES TO FECHTO-REG
               STRING 'TOTAL SALDO SNAPSHOT GDG      : '
                      WS-EDIT-SALDOS
                      DELIMITED BY SIZE INTO FECHTO-REG
               END-STRING
               WRITE FECHTO-REG
           END-IF

           MOVE WS-CONCIL-LIDOS TO WS-EDIT-NUM
           MOVE SPACES TO FECHTO-REG
           STRING 'REGISTROS DE CONCILIACAO      : '
                  WS-EDIT-NUM
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE ALL '-' TO FECHTO-REG
           WRITE FECHTO-REG

           IF CONCIL-DIVERGENTE
               MOVE SPACES TO FECHTO-REG
               MOVE '*** CONCILIACAO COM DIVERGENCIA - VER CONCIL.SEQ'
                   TO FECHTO-REG
               WRITE FECHTO-REG
           END-IF

           IF TEM-DIVERGENCIA
               MOVE SPACES TO FECHTO-REG
               MOVE '*** ALERTA: DIVERGENCIAS DETECTADAS NO DIA ***'
                   TO FECHTO-REG
               WRITE FECHTO-REG
           ELSE
               MOVE SPACES TO FECHTO-REG
               MOVE 'FECHAMENTO CONCLUIDO COM SUCESSO'
                   TO FECHTO-REG
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
                      DELIMITED BY SIZE INTO AUDIT-REG
               END-STRING
           ELSE
               STRING 'EOD FECHAMENTO OK - DATA '
                      WS-DATA-SISTEMA
                      ' HORA '
                      WS-HORA-SISTEMA
                      DELIMITED BY SIZE INTO AUDIT-REG
               END-STRING
           END-IF

           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** ERRO WRITE AUDIT - STATUS: '
                       WS-FS-AUDIT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Le snapshot GDG e totaliza saldo (arquivo opcional)           *
      * Falha de OPEN nao bloqueia o fechamento                       *
      *---------------------------------------------------------------*
       6000-LER-SALDO-GDG.
           OPEN INPUT SALDO-IN
           IF FS-SALDO-OK
               SET SALDO-DISPONIVEL TO TRUE
               PERFORM UNTIL EOF-SALDO OR OCORREU-ERRO-IO
                   READ SALDO-IN
                       AT END
                           SET EOF-SALDO TO TRUE
                       NOT AT END
                           IF FS-SALDO-OK
                               ADD SLD-SALDO TO WS-SOMA-SALDO-GDG
                           ELSE
                               DISPLAY '*** ERRO READ SALDOIN - '
                                       WS-FS-SALDO
                               SET OCORREU-ERRO-IO TO TRUE
                           END-IF
                   END-READ
               END-PERFORM
               CLOSE SALDO-IN
               IF NOT FS-SALDO-OK
                   DISPLAY '*** ERRO CLOSE SALDOIN - STATUS: '
                           WS-FS-SALDO
               END-IF
           ELSE
               DISPLAY '*** AVISO: SALDOIN indisponivel - '
                       'total GDG ignorado no relatorio.'
           END-IF.

      *---------------------------------------------------------------*
      * Fecha arquivos com verificacao de FILE STATUS                 *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF CONCIN-ABERTO
               CLOSE CONCIL-IN
               IF NOT FS-CONCIN-OK
                   DISPLAY '*** ERRO CLOSE CONCIL-IN - STATUS: '
                           WS-FS-CONCIN
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF CONTA-ABERTO
               CLOSE CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** ERRO CLOSE CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF FECHOUT-ABERTO
               CLOSE FECHTO-OUT
               IF NOT FS-FECHOUT-OK
                   DISPLAY '*** ERRO CLOSE FECHTO-OUT - STATUS: '
                           WS-FS-FECHOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF AUDIT-ABERTO
               CLOSE AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** ERRO CLOSE AUDIT-OUT - STATUS: '
                           WS-FS-AUDIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

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
           DISPLAY 'TOTAL SALDOS (KSDS)    : ' WS-TOTAL-SALDOS
           IF SALDO-DISPONIVEL
               DISPLAY 'TOTAL SALDOS (GDG)     : ' WS-SOMA-SALDO-GDG
           END-IF

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN TEM-DIVERGENCIA
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
