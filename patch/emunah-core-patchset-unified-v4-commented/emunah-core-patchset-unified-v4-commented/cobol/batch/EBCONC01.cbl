      *===============================================================*
      * ARQUIVO   : EBCONC01.cbl                                       *
      * CAMINHO   : cobol/batch/EBCONC01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Executar a conciliação three-way do ciclo diário.*
      *                                                               *
      * ENTRADAS  : ENTRIN, MOVTIN, REJEIT, SALDOIN(opcional), CONTA*
      * SAIDAS    : CONCOUT                                        *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Check 1: COUNT(ENTRIN) = COUNT(MOVTIN) + COUNT(REJEIT).    *
      * - Check 2: liquidez do dia (informativo).                    *
      * - Check 3: soma do snapshot GDG versus soma atual do KSDS de *
      *   contas.                                                    *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCONC01.
      *===============================================================*
      * PROGRAMA : EBCONC01                                           *
      * FUNCAO   : CONCILIACAO TRES-VIAS                              *
      * SAIDA    : CONCIL.SEQ (132 bytes, layout estruturado)         *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ENTRIN-IN
               ASSIGN TO ENTRIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ENTRIN.

           SELECT MOVTO-IN
               ASSIGN TO MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

           SELECT REJEIT-IN
               ASSIGN TO REJEIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJEIT.

           SELECT SALDO-IN
               ASSIGN TO SALDOIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

           SELECT CONCIL-OUT
               ASSIGN TO CONCOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONCOUT.

       DATA DIVISION.
       FILE SECTION.
       FD  ENTRIN-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ENTRIN-REG                 PIC X(120).

       FD  MOVTO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  MOVTO-REG.
           COPY CPLCT001.

       FD  REJEIT-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-REG                 PIC X(120).

       FD  SALDO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-REG.
           COPY CPSNP001.

       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

       FD  CONCIL-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  CONCIL-REG.
           COPY CPCONC001.

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-FS-ENTRIN            PIC XX VALUE SPACES.
              88 FS-ENTRIN-OK         VALUE '00'.
              88 FS-ENTRIN-EOF        VALUE '10'.
           05 WS-FS-MOVTIN            PIC XX VALUE SPACES.
              88 FS-MOVTIN-OK         VALUE '00'.
              88 FS-MOVTIN-EOF        VALUE '10'.
           05 WS-FS-REJEIT            PIC XX VALUE SPACES.
              88 FS-REJEIT-OK         VALUE '00'.
              88 FS-REJEIT-EOF        VALUE '10'.
           05 WS-FS-SALDO             PIC XX VALUE SPACES.
              88 FS-SALDO-OK          VALUE '00'.
              88 FS-SALDO-EOF         VALUE '10'.
           05 WS-FS-CONTA             PIC XX VALUE SPACES.
              88 FS-CONTA-OK          VALUE '00'.
              88 FS-CONTA-EOF         VALUE '10'.
           05 WS-FS-CONCOUT           PIC XX VALUE SPACES.
              88 FS-CONCOUT-OK        VALUE '00'.

       01  WS-FLAGS.
           05 WS-EOF-ENTRIN           PIC X VALUE 'N'.
              88 EOF-ENTRIN           VALUE 'S'.
           05 WS-EOF-MOVTIN           PIC X VALUE 'N'.
              88 EOF-MOVTIN           VALUE 'S'.
           05 WS-EOF-REJEIT           PIC X VALUE 'N'.
              88 EOF-REJEIT           VALUE 'S'.
           05 WS-EOF-SALDO            PIC X VALUE 'N'.
              88 EOF-SALDO            VALUE 'S'.
           05 WS-EOF-CONTA            PIC X VALUE 'N'.
              88 EOF-CONTA            VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
           05 WS-SALDO-DISP           PIC X VALUE 'N'.
              88 SALDO-DISPONIVEL     VALUE 'S'.

       01  WS-CONTADORES.
           05 WS-CT-ENTRIN            PIC 9(9) VALUE ZERO.
           05 WS-CT-MOVTIN            PIC 9(9) VALUE ZERO.
           05 WS-CT-REJEIT            PIC 9(9) VALUE ZERO.
           05 WS-CT-CONTA             PIC 9(9) VALUE ZERO.

       01  WS-TOTAIS.
           05 WS-SOMA-CREDITOS        PIC S9(15)V99 VALUE ZERO.
           05 WS-SOMA-DEBITOS         PIC S9(15)V99 VALUE ZERO.
           05 WS-MOV-LIQUIDO          PIC S9(15)V99 VALUE ZERO.
           05 WS-SOMA-SALDO-GDG       PIC S9(15)V99 VALUE ZERO.
           05 WS-SOMA-SALDO-CONTA     PIC S9(15)V99 VALUE ZERO.
           05 WS-VALOR-AUX            PIC S9(15)V99 VALUE ZERO.

       01  WS-CHECKS.
           05 WS-CHECK1-OK            PIC X VALUE 'N'.
              88 CHECK1-PASSOU        VALUE 'S'.
           05 WS-CHECK3-OK            PIC X VALUE 'N'.
              88 CHECK3-PASSOU        VALUE 'S'.

       01  WS-DATA-SISTEMA            PIC 9(8).
       01  WS-HORA-SISTEMA            PIC 9(8).
       01  WS-VALOR-EDIT              PIC -Z(10)9,99.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME
           PERFORM 1000-ABRIR-ARQUIVOS
           IF NOT OCORREU-ERRO-IO
               PERFORM 2000-CONTAR-ENTRIN
               PERFORM 2100-LER-MOVTIN
               PERFORM 2200-CONTAR-REJEIT
               PERFORM 2300-SOMAR-SALDOIN
               PERFORM 2400-SOMAR-CONTA
               PERFORM 3000-EXECUTAR-CHECKS
               PERFORM 4000-GERAR-SAIDA
           END-IF
           PERFORM 9000-FECHAR
           PERFORM 9100-RETORNO
           GOBACK.

       1000-ABRIR-ARQUIVOS.
           OPEN INPUT ENTRIN-IN
           IF NOT FS-ENTRIN-OK
               DISPLAY '*** EBCONC01 ERRO OPEN ENTRIN - ' WS-FS-ENTRIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT MOVTO-IN
               IF NOT FS-MOVTIN-OK
                   DISPLAY '*** EBCONC01 ERRO OPEN MOVTIN - ' WS-FS-MOVTIN
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT REJEIT-IN
               IF NOT FS-REJEIT-OK
                   DISPLAY '*** EBCONC01 ERRO OPEN REJEIT - ' WS-FS-REJEIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** EBCONC01 ERRO OPEN CONTA - ' WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN OUTPUT CONCIL-OUT
               IF NOT FS-CONCOUT-OK
                   DISPLAY '*** EBCONC01 ERRO OPEN CONCOUT - '
                           WS-FS-CONCOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT SALDO-IN
               IF FS-SALDO-OK
                   SET SALDO-DISPONIVEL TO TRUE
               ELSE
                   DISPLAY '*** EBCONC01 AVISO - SALDOIN indisponivel.'
               END-IF
           END-IF.

       2000-CONTAR-ENTRIN.
           PERFORM UNTIL EOF-ENTRIN OR OCORREU-ERRO-IO
               READ ENTRIN-IN
                   AT END
                       SET EOF-ENTRIN TO TRUE
                   NOT AT END
                       IF FS-ENTRIN-OK
                           ADD 1 TO WS-CT-ENTRIN
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       2100-LER-MOVTIN.
           PERFORM UNTIL EOF-MOVTIN OR OCORREU-ERRO-IO
               READ MOVTO-IN
                   AT END
                       SET EOF-MOVTIN TO TRUE
                   NOT AT END
                       IF FS-MOVTIN-OK
                           ADD 1 TO WS-CT-MOVTIN
                           EVALUATE LCT-TIPO
                               WHEN 'C'
                                   ADD LCT-VALOR TO WS-SOMA-CREDITOS
                               WHEN 'D'
                                   ADD LCT-VALOR TO WS-SOMA-DEBITOS
                           END-EVALUATE
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM
           COMPUTE WS-MOV-LIQUIDO =
               WS-SOMA-CREDITOS - WS-SOMA-DEBITOS.

       2200-CONTAR-REJEIT.
           PERFORM UNTIL EOF-REJEIT OR OCORREU-ERRO-IO
               READ REJEIT-IN
                   AT END
                       SET EOF-REJEIT TO TRUE
                   NOT AT END
                       IF FS-REJEIT-OK
                           ADD 1 TO WS-CT-REJEIT
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       2300-SOMAR-SALDOIN.
           IF NOT SALDO-DISPONIVEL
               EXIT PARAGRAPH
           END-IF

           PERFORM UNTIL EOF-SALDO OR OCORREU-ERRO-IO
               READ SALDO-IN
                   AT END
                       SET EOF-SALDO TO TRUE
                   NOT AT END
                       IF FS-SALDO-OK
                           ADD SNP-SALDO TO WS-SOMA-SALDO-GDG
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       2400-SOMAR-CONTA.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-CONTA
                           ADD CNT-SALDO OF CONTA-REG
                               TO WS-SOMA-SALDO-CONTA
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

       3000-EXECUTAR-CHECKS.
           IF WS-CT-ENTRIN = WS-CT-MOVTIN + WS-CT-REJEIT
               SET CHECK1-PASSOU TO TRUE
           END-IF

           IF NOT SALDO-DISPONIVEL
               SET CHECK3-PASSOU TO TRUE
           ELSE
               IF WS-SOMA-SALDO-GDG = WS-SOMA-SALDO-CONTA
                   SET CHECK3-PASSOU TO TRUE
               END-IF
           END-IF.

       4000-GERAR-SAIDA.
           PERFORM 4100-LINHA-H11
           PERFORM 4110-LINHA-D11
           PERFORM 4120-LINHA-D12
           PERFORM 4130-LINHA-D13
           PERFORM 4140-LINHA-D14
           PERFORM 4150-LINHA-R11
           PERFORM 4200-LINHA-H21
           PERFORM 4210-LINHA-D21
           PERFORM 4220-LINHA-D22
           PERFORM 4230-LINHA-R21
           PERFORM 4300-LINHA-H31
           PERFORM 4310-LINHA-D31
           PERFORM 4320-LINHA-D32
           PERFORM 4330-LINHA-D33
           PERFORM 4340-LINHA-D34
           PERFORM 4350-LINHA-R31
           PERFORM 4400-LINHA-T98
           PERFORM 4410-LINHA-T99.

       4100-LINHA-H11.
           MOVE SPACES TO CONCIL-REG
           MOVE 'H11' TO CC-TIPO-REG
           MOVE 'SECAO 1 - ENTRADA X VALIDOS + REJEITOS' TO CC-DESCRICAO
           MOVE 'INICIO' TO CC-STATUS
           PERFORM 4900-WRITE.

       4110-LINHA-D11.
           MOVE WS-CT-ENTRIN TO WS-VALOR-AUX
           MOVE WS-VALOR-AUX TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D11' TO CC-TIPO-REG
           MOVE 'TOTAL ENTRADA' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'ARQ.ENTRADA.SEQ' TO CC-STATUS
           PERFORM 4900-WRITE.

       4120-LINHA-D12.
           MOVE WS-CT-MOVTIN TO WS-VALOR-AUX
           MOVE WS-VALOR-AUX TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D12' TO CC-TIPO-REG
           MOVE 'TOTAL VALIDOS/POSTADOS' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'ARQ.LANCTO.ESDS' TO CC-STATUS
           PERFORM 4900-WRITE.

       4130-LINHA-D13.
           MOVE WS-CT-REJEIT TO WS-VALOR-AUX
           MOVE WS-VALOR-AUX TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D13' TO CC-TIPO-REG
           MOVE 'TOTAL REJEITOS' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'ARQ.REJEITOS.SEQ' TO CC-STATUS
           PERFORM 4900-WRITE.

       4140-LINHA-D14.
           MOVE WS-CT-MOVTIN TO WS-VALOR-AUX
           ADD WS-CT-REJEIT TO WS-VALOR-AUX
           MOVE WS-VALOR-AUX TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D14' TO CC-TIPO-REG
           MOVE 'VALIDOS + REJEITOS' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'BASE DE COMPARACAO' TO CC-STATUS
           PERFORM 4900-WRITE.

       4150-LINHA-R11.
           MOVE SPACES TO CONCIL-REG
           MOVE 'R11' TO CC-TIPO-REG
           MOVE 'RESULTADO SECAO 1' TO CC-DESCRICAO
           IF CHECK1-PASSOU
               MOVE 'OK' TO CC-STATUS
           ELSE
               MOVE 'DIVERGENTE - ENTRADA <> VALIDOS+REJEITOS'
                 TO CC-STATUS
           END-IF
           PERFORM 4900-WRITE.

       4200-LINHA-H21.
           MOVE SPACES TO CONCIL-REG
           MOVE 'H21' TO CC-TIPO-REG
           MOVE 'SECAO 2 - LIQUIDEZ DOS MOVIMENTOS' TO CC-DESCRICAO
           MOVE 'INICIO' TO CC-STATUS
           PERFORM 4900-WRITE.

       4210-LINHA-D21.
           MOVE WS-SOMA-CREDITOS TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D21' TO CC-TIPO-REG
           MOVE 'TOTAL CREDITOS' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'MOVTIN TIPO C' TO CC-STATUS
           PERFORM 4900-WRITE.

       4220-LINHA-D22.
           MOVE WS-SOMA-DEBITOS TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D22' TO CC-TIPO-REG
           MOVE 'TOTAL DEBITOS' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'MOVTIN TIPO D' TO CC-STATUS
           PERFORM 4900-WRITE.

       4230-LINHA-R21.
           MOVE SPACES TO CONCIL-REG
           MOVE 'R21' TO CC-TIPO-REG
           MOVE 'RESULTADO SECAO 2' TO CC-DESCRICAO
           MOVE WS-MOV-LIQUIDO TO WS-VALOR-EDIT
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'OK - INFORMATIVO (CREDITOS - DEBITOS)'
             TO CC-STATUS
           PERFORM 4900-WRITE.

       4300-LINHA-H31.
           MOVE SPACES TO CONCIL-REG
           MOVE 'H31' TO CC-TIPO-REG
           MOVE 'SECAO 3 - SNAPSHOT X POSICAO FINAL' TO CC-DESCRICAO
           MOVE 'INICIO' TO CC-STATUS
           PERFORM 4900-WRITE.

       4310-LINHA-D31.
           MOVE WS-SOMA-SALDO-GDG TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D31' TO CC-TIPO-REG
           MOVE 'TOTAL SNAPSHOT GDG' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           IF SALDO-DISPONIVEL
               MOVE 'SALDOIN DISPONIVEL' TO CC-STATUS
           ELSE
               MOVE 'SALDOIN AUSENTE' TO CC-STATUS
           END-IF
           PERFORM 4900-WRITE.

       4320-LINHA-D32.
           MOVE WS-SOMA-SALDO-CONTA TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D32' TO CC-TIPO-REG
           MOVE 'TOTAL KSDS CONTA' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'SOMA DA POSICAO FINAL' TO CC-STATUS
           PERFORM 4900-WRITE.

       4330-LINHA-D33.
           MOVE WS-MOV-LIQUIDO TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D33' TO CC-TIPO-REG
           MOVE 'MOVIMENTO LIQUIDO' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'CREDITOS - DEBITOS' TO CC-STATUS
           PERFORM 4900-WRITE.

       4340-LINHA-D34.
           COMPUTE WS-VALOR-AUX = WS-SOMA-SALDO-CONTA - WS-SOMA-SALDO-GDG
           MOVE WS-VALOR-AUX TO WS-VALOR-EDIT
           MOVE SPACES TO CONCIL-REG
           MOVE 'D34' TO CC-TIPO-REG
           MOVE 'DELTA KSDS - SNAPSHOT' TO CC-DESCRICAO
           MOVE WS-VALOR-EDIT TO CC-VALOR
           MOVE 'ZERO ESPERADO NO FECHAMENTO' TO CC-STATUS
           PERFORM 4900-WRITE.

       4350-LINHA-R31.
           MOVE SPACES TO CONCIL-REG
           MOVE 'R31' TO CC-TIPO-REG
           MOVE 'RESULTADO SECAO 3' TO CC-DESCRICAO
           IF CHECK3-PASSOU
               MOVE 'OK' TO CC-STATUS
           ELSE
               MOVE 'DIVERGENTE - SNAPSHOT <> POSICAO FINAL'
                 TO CC-STATUS
           END-IF
           PERFORM 4900-WRITE.

       4400-LINHA-T98.
           MOVE SPACES TO CONCIL-REG
           MOVE 'T98' TO CC-TIPO-REG
           MOVE 'TIMESTAMP DA CONCILIACAO' TO CC-DESCRICAO
           MOVE WS-DATA-SISTEMA TO CC-STATUS(1:8)
           MOVE WS-HORA-SISTEMA TO CC-STATUS(10:8)
           PERFORM 4900-WRITE.

       4410-LINHA-T99.
           MOVE SPACES TO CONCIL-REG
           MOVE 'T99' TO CC-TIPO-REG
           MOVE 'STATUS GERAL DO DIA' TO CC-DESCRICAO
           EVALUATE TRUE
               WHEN NOT CHECK1-PASSOU
                   MOVE 'DIVERGENTE - BLOQUEAR EOD' TO CC-STATUS
               WHEN NOT CHECK3-PASSOU
                   MOVE 'ALERTA - VERIFICAR SNAPSHOT/POSTAGEM'
                     TO CC-STATUS
               WHEN OTHER
                   MOVE 'OK - DIA APTO PARA EOD' TO CC-STATUS
           END-EVALUATE
           PERFORM 4900-WRITE.

       4900-WRITE.
           WRITE CONCIL-REG
           IF NOT FS-CONCOUT-OK
               DISPLAY '*** EBCONC01 ERRO WRITE CONCOUT - '
                       WS-FS-CONCOUT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

       9000-FECHAR.
           CLOSE ENTRIN-IN
           CLOSE MOVTO-IN
           CLOSE REJEIT-IN
           IF SALDO-DISPONIVEL
               CLOSE SALDO-IN
           END-IF
           CLOSE CONTA-KSDS
           CLOSE CONCIL-OUT.

       9100-RETORNO.
           DISPLAY '*** RESUMO EBCONC01 ***'
           DISPLAY 'ENTRADA   : ' WS-CT-ENTRIN
           DISPLAY 'VALIDOS   : ' WS-CT-MOVTIN
           DISPLAY 'REJEITOS  : ' WS-CT-REJEIT
           DISPLAY 'CONTA KSDS: ' WS-CT-CONTA
           DISPLAY 'LIQUIDO   : ' WS-MOV-LIQUIDO
           IF OCORREU-ERRO-IO
               MOVE 8 TO RETURN-CODE
           ELSE
               IF NOT CHECK1-PASSOU
                   MOVE 8 TO RETURN-CODE
               ELSE
                   IF NOT CHECK3-PASSOU
                       MOVE 4 TO RETURN-CODE
                   ELSE
                       MOVE 0 TO RETURN-CODE
                   END-IF
               END-IF
           END-IF.
