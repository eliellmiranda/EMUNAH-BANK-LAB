       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBSNAP01.
      *===============================================================*
      * PROGRAMA : EBSNAP01                                           *
      * FUNCAO   : SNAPSHOT DE SALDO DIARIO                           *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o KSDS de contas sequencialmente                         *
      * - Grava uma geracao nova de SALDO.GDG(+1) com o saldo         *
      *   final de cada conta no formato: AG, CONTA, SALDO, DATA      *
      * - Grava registro de auditoria                                 *
      *                                                               *
      * QUANDO RODA:                                                  *
      *   Apos EBJPOST (saldos ja atualizados) e antes de EBJCONC.    *
      *   O SALDO.GDG(0) gerado e lido pelo EBCONC01 e EBJEOD01.      *
      *                                                               *
      * LAYOUT SALDO.GDG (120 bytes):                                  *
      *   SLD-AGENCIA    PIC 9(4)      pos 1-4                        *
      *   SLD-NUM-CONTA  PIC 9(8)      pos 5-12                       *
      *   SLD-SALDO      PIC S9(11)V99 pos 13-25                      *
      *   SLD-DATA       PIC X(8)      pos 26-33 (AAAAMMDD)           *
      *   FILLER         PIC X(87)     pos 34-120                     *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Snapshot gerado com sucesso                     *
      *   RC = 4  --> KSDS vazio (alerta)                             *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CONTA = KSDS master de contas (leitura sequencial)            *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * SALDOUT = geracao nova do GDG de saldo (SALDO.GDG(+1))        *
      *---------------------------------------------------------------*
           SELECT SALDO-OUT
               ASSIGN TO SALDOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

      *---------------------------------------------------------------*
      * AUDIT = trilha de auditoria (DISP=MOD no JCL)                 *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * KSDS de contas (layout via CPCNT001)                          *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Snapshot de saldo - 120 bytes                                 *
      *---------------------------------------------------------------*
       FD  SALDO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-REG.
           05 SLD-AGENCIA             PIC 9(4).
           05 SLD-NUM-CONTA           PIC 9(8).
           05 SLD-SALDO               PIC S9(11)V99.
           05 SLD-DATA                PIC X(8).
           05 FILLER                  PIC X(87).

      *---------------------------------------------------------------*
      * Auditoria - 120 bytes                                         *
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
           05 WS-FS-CONTA             PIC XX VALUE SPACES.
              88 FS-CONTA-OK          VALUE '00'.
              88 FS-CONTA-EOF         VALUE '10'.
           05 WS-FS-SALDO             PIC XX VALUE SPACES.
              88 FS-SALDO-OK          VALUE '00'.
           05 WS-FS-AUDIT             PIC XX VALUE SPACES.
              88 FS-AUDIT-OK          VALUE '00'.

      *---------------------------------------------------------------*
      * Controles                                                     *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-CONTA            PIC X VALUE 'N'.
              88 EOF-CONTA            VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ABERTOS.
           05 WS-CONTA-ABERTO         PIC X VALUE 'N'.
              88 CONTA-ABERTO         VALUE 'S'.
           05 WS-SALDO-ABERTO         PIC X VALUE 'N'.
              88 SALDO-ABERTO         VALUE 'S'.
           05 WS-AUDIT-ABERTO         PIC X VALUE 'N'.
              88 AUDIT-ABERTO         VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores                                                    *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CT-LIDAS             PIC 9(9) VALUE ZERO.
           05 WS-CT-GRAVADAS          PIC 9(9) VALUE ZERO.
           05 WS-CT-IGNORADAS         PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Totalizador para evidencia no SYSOUT                          *
      *---------------------------------------------------------------*
       01  WS-TOTAL-SALDO             PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora do sistema                                        *
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
               PERFORM 2000-GERAR-SNAPSHOT
               PERFORM 3000-GRAVAR-AUDITORIA
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre arquivos com verificacao de FILE STATUS                  *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT CONTA-KSDS
           IF FS-CONTA-OK
               SET CONTA-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN CONTA-KSDS - STATUS: '
                       WS-FS-CONTA
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT SALDO-OUT
               IF FS-SALDO-OK
                   SET SALDO-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN SALDO-OUT - STATUS: '
                           WS-FS-SALDO
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
      * Percorre KSDS e grava snapshot de cada conta                  *
      * Contas inativas e bloqueadas sao incluidas no snapshot        *
      * (saldo ainda e posicao oficial do banco)                      *
      *---------------------------------------------------------------*
       2000-GERAR-SNAPSHOT.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-LIDAS
                           PERFORM 2100-GRAVAR-REGISTRO-SALDO
                       ELSE
                           DISPLAY '*** ERRO READ CONTA-KSDS - '
                                   WS-FS-CONTA
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Monta e grava o registro de snapshot                          *
      *---------------------------------------------------------------*
       2100-GRAVAR-REGISTRO-SALDO.
           MOVE CNT-AGENCIA    OF CONTA-REG TO SLD-AGENCIA
           MOVE CNT-NUM-CONTA  OF CONTA-REG TO SLD-NUM-CONTA
           MOVE CNT-SALDO      OF CONTA-REG TO SLD-SALDO
           MOVE WS-DATA-SISTEMA             TO SLD-DATA

           WRITE SALDO-REG
           IF FS-SALDO-OK
               ADD 1           TO WS-CT-GRAVADAS
               ADD SLD-SALDO   TO WS-TOTAL-SALDO
           ELSE
               DISPLAY '*** ERRO WRITE SALDO-OUT - STATUS: '
                       WS-FS-SALDO
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Grava registro de auditoria do snapshot                       *
      *---------------------------------------------------------------*
       3000-GRAVAR-AUDITORIA.
           MOVE SPACES TO AUDIT-REG
           STRING 'EBSNAP01 SNAPSHOT OK - DATA '
                  WS-DATA-SISTEMA
                  ' HORA '
                  WS-HORA-SISTEMA
                  ' CONTAS='
                  WS-CT-GRAVADAS
                  DELIMITED BY SIZE INTO AUDIT-REG
           END-STRING
           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** ERRO WRITE AUDIT - STATUS: '
                       WS-FS-AUDIT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Fecha arquivos com verificacao de FILE STATUS                 *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF CONTA-ABERTO
               CLOSE CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** ERRO CLOSE CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF SALDO-ABERTO
               CLOSE SALDO-OUT
               IF NOT FS-SALDO-OK
                   DISPLAY '*** ERRO CLOSE SALDO-OUT - STATUS: '
                           WS-FS-SALDO
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
           DISPLAY '*** RESUMO SNAPSHOT DE SALDO ***'
           DISPLAY 'CONTAS LIDAS     : ' WS-CT-LIDAS
           DISPLAY 'REGISTROS GRAVADOS: ' WS-CT-GRAVADAS
           DISPLAY 'TOTAL SALDO GDG  : ' WS-TOTAL-SALDO

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-CT-GRAVADAS = ZERO
                   DISPLAY '*** ATENCAO: KSDS VAZIO - GDG CRIADO VAZIO'
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.