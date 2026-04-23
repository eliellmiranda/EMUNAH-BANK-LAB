      *===============================================================*
      * ARQUIVO   : EBJEOD01.cbl                                       *
      * CAMINHO   : cobol/batch/EBJEOD01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Consolidar a evidência do fechamento diário antes de CLOSED.*
      *                                                               *
      * ENTRADAS  : CONCIN, CONTA, SALDOIN(opcional), AUDIT        *
      * SAIDAS    : FECHOUT e/ou AUDIT complementar                *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Não deve ser tratado como substituto da conciliação.       *
      * - Resume o dia e prepara o encerramento formal.              *
      * - Deve rodar antes da transição para CLOSED.                 *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBJEOD01.
      *===============================================================*
      * PROGRAMA : EBJEOD01                                           *
      * FUNCAO   : FECHAMENTO DIARIO                                  *
      * ENTRADAS  : CONCIN / SALDOIN / CONTA                          *
      * SAIDA     : FECHOUT (132 bytes)                               *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CONCIL-IN
               ASSIGN TO CONCIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONCIN.

           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

           SELECT FECHTO-OUT
               ASSIGN TO FECHOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-FECHOUT.

           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

           SELECT SALDO-IN
               ASSIGN TO SALDOIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

       DATA DIVISION.
       FILE SECTION.
       FD  CONCIL-IN
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  CONCIL-REG.
           COPY CPCONC001.

       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

       FD  FECHTO-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  FECHTO-REG                PIC X(132).

       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                 PIC X(120).

       FD  SALDO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-REG.
           COPY CPSNP001.

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS-CONCIN           PIC XX VALUE SPACES.
              88 FS-CONCIN-OK        VALUE '00'.
              88 FS-CONCIN-EOF       VALUE '10'.
           05 WS-FS-CONTA            PIC XX VALUE SPACES.
              88 FS-CONTA-OK         VALUE '00'.
              88 FS-CONTA-EOF        VALUE '10'.
           05 WS-FS-FECHOUT          PIC XX VALUE SPACES.
              88 FS-FECHOUT-OK       VALUE '00'.
           05 WS-FS-AUDIT            PIC XX VALUE SPACES.
              88 FS-AUDIT-OK         VALUE '00'.
           05 WS-FS-SALDO            PIC XX VALUE SPACES.
              88 FS-SALDO-OK         VALUE '00'.
              88 FS-SALDO-EOF        VALUE '10'.

       01  WS-FLAGS.
           05 WS-EOF-CONCIN          PIC X VALUE 'N'.
              88 EOF-CONCIN          VALUE 'S'.
           05 WS-EOF-CONTA           PIC X VALUE 'N'.
              88 EOF-CONTA           VALUE 'S'.
           05 WS-EOF-SALDO           PIC X VALUE 'N'.
              88 EOF-SALDO           VALUE 'S'.
           05 WS-ERRO-IO             PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO     VALUE 'S'.
           05 WS-SALDO-DISP          PIC X VALUE 'N'.
              88 SALDO-DISPONIVEL    VALUE 'S'.
           05 WS-DIV-CONTAGEM        PIC X VALUE 'N'.
              88 DIV-CONTAGEM        VALUE 'S'.
           05 WS-DIV-SALDO           PIC X VALUE 'N'.
              88 DIV-SALDO           VALUE 'S'.

       01  WS-TOTAIS.
           05 WS-TOTAL-SALDO-GDG     PIC S9(15)V99 VALUE ZERO.
           05 WS-TOTAL-SALDO-CONTA   PIC S9(15)V99 VALUE ZERO.
           05 WS-CT-CONTA            PIC 9(9) VALUE ZERO.

       01  WS-DATA-SISTEMA           PIC 9(8).
       01  WS-HORA-SISTEMA           PIC 9(8).
       01  WS-VALOR-EDIT             PIC -Z(10)9,99.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME
           PERFORM 1000-ABRIR
           IF NOT OCORREU-ERRO-IO
               PERFORM 2000-LER-CONCILIACAO
               PERFORM 3000-LER-SALDO-GDG
               PERFORM 4000-LER-CONTA
               PERFORM 5000-GERAR-FECHAMENTO
               PERFORM 6000-GRAVAR-AUDITORIA
           END-IF
           PERFORM 9000-FECHAR
           PERFORM 9100-RETORNO
           GOBACK.

       1000-ABRIR.
           OPEN INPUT CONCIL-IN
           IF NOT FS-CONCIN-OK
               DISPLAY '*** EBJEOD01 ERRO OPEN CONCIN - ' WS-FS-CONCIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** EBJEOD01 ERRO OPEN CONTA - ' WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN OUTPUT FECHTO-OUT
               IF NOT FS-FECHOUT-OK
                   DISPLAY '*** EBJEOD01 ERRO OPEN FECHOUT - '
                           WS-FS-FECHOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN EXTEND AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** EBJEOD01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT SALDO-IN
               IF FS-SALDO-OK
                   SET SALDO-DISPONIVEL TO TRUE
               ELSE
                   DISPLAY '*** EBJEOD01 AVISO - SALDOIN indisponivel.'
               END-IF
           END-IF.

       2000-LER-CONCILIACAO.
           PERFORM UNTIL EOF-CONCIN OR OCORREU-ERRO-IO
               READ CONCIL-IN
                   AT END
                       SET EOF-CONCIN TO TRUE
                   NOT AT END
                       IF FS-CONCIN-OK
                           IF CC-TIPO-REG = 'R11'
                              AND CC-STATUS(1:10) = 'DIVERGENTE'
                               SET DIV-CONTAGEM TO TRUE
                           END-IF
                           IF CC-TIPO-REG = 'R31'
                              AND CC-STATUS(1:10) = 'DIVERGENTE'
                               SET DIV-SALDO TO TRUE
                           END-IF
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       3000-LER-SALDO-GDG.
           IF NOT SALDO-DISPONIVEL
               EXIT PARAGRAPH
           END-IF

           PERFORM UNTIL EOF-SALDO OR OCORREU-ERRO-IO
               READ SALDO-IN
                   AT END
                       SET EOF-SALDO TO TRUE
                   NOT AT END
                       IF FS-SALDO-OK
                           ADD SNP-SALDO TO WS-TOTAL-SALDO-GDG
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       4000-LER-CONTA.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-CONTA
                           ADD CNT-SALDO OF CONTA-REG
                               TO WS-TOTAL-SALDO-CONTA
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       5000-GERAR-FECHAMENTO.
           MOVE SPACES TO FECHTO-REG
           STRING 'FECHAMENTO EMUNAH BANK - DATA '
                  WS-DATA-SISTEMA
                  ' HORA '
                  WS-HORA-SISTEMA
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           MOVE WS-TOTAL-SALDO-GDG TO WS-VALOR-EDIT
           STRING 'TOTAL SNAPSHOT GDG : ' WS-VALOR-EDIT
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           MOVE WS-TOTAL-SALDO-CONTA TO WS-VALOR-EDIT
           STRING 'TOTAL POSICAO KSDS : ' WS-VALOR-EDIT
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL CONTAS LIDAS  : ' WS-CT-CONTA
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           EVALUATE TRUE
               WHEN DIV-CONTAGEM
                   MOVE 'STATUS FECHAMENTO: BLOQUEADO POR DIVERGENCIA '
                        TO FECHTO-REG
               WHEN DIV-SALDO
                   MOVE 'STATUS FECHAMENTO: ALERTA DE SALDO - REVISAO '
                        TO FECHTO-REG
               WHEN OTHER
                   MOVE 'STATUS FECHAMENTO: OK - APTO A FECHAR O DIA' 
                        TO FECHTO-REG
           END-EVALUATE
           WRITE FECHTO-REG.

       6000-GRAVAR-AUDITORIA.
           MOVE SPACES TO AUDIT-REG
           EVALUATE TRUE
               WHEN DIV-CONTAGEM
                   MOVE 'EBJEOD01 - BLOQUEIO POR DIVERGENCIA DE CONTAGEM'
                     TO AUDIT-REG
               WHEN DIV-SALDO
                   MOVE 'EBJEOD01 - ALERTA POR DIVERGENCIA DE SALDO'
                     TO AUDIT-REG
               WHEN OTHER
                   MOVE 'EBJEOD01 - FECHAMENTO OK' TO AUDIT-REG
           END-EVALUATE
           WRITE AUDIT-REG.

       9000-FECHAR.
           CLOSE CONCIL-IN
           IF SALDO-DISPONIVEL
               CLOSE SALDO-IN
           END-IF
           CLOSE CONTA-KSDS
           CLOSE FECHTO-OUT
           CLOSE AUDIT-OUT.

       9100-RETORNO.
           DISPLAY '*** RESUMO EBJEOD01 ***'
           DISPLAY 'CONTAS: ' WS-CT-CONTA
           DISPLAY 'SALDO GDG : ' WS-TOTAL-SALDO-GDG
           DISPLAY 'SALDO KSDS: ' WS-TOTAL-SALDO-CONTA
           IF OCORREU-ERRO-IO
               MOVE 8 TO RETURN-CODE
           ELSE
               IF DIV-CONTAGEM
                   MOVE 8 TO RETURN-CODE
               ELSE
                   IF DIV-SALDO
                       MOVE 4 TO RETURN-CODE
                   ELSE
                       MOVE 0 TO RETURN-CODE
                   END-IF
               END-IF
           END-IF.
