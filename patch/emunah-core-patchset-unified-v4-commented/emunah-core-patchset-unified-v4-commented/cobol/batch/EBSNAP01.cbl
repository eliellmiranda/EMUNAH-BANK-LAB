      *===============================================================*
      * ARQUIVO   : EBSNAP01.cbl                                       *
      * CAMINHO   : cobol/batch/EBSNAP01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Gerar o snapshot diário de saldo a partir de CONTA.KSDS.*
      *                                                               *
      * ENTRADAS  : CONTA                                          *
      * SAIDAS    : SALDOUT                                        *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Percorre todas as contas do master.                        *
      * - Grava uma fotografia posicional do saldo do dia.           *
      * - Alimenta conciliação e fechamento.                         *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
 IDENTIFICATION DIVISION.
 PROGRAM-ID. EBSNAP01.
*===============================================================*
* PROGRAMA : EBSNAP01                                           *
* FUNCAO   : GERAR SNAPSHOT DIARIO DE SALDO                     *
*===============================================================*

 ENVIRONMENT DIVISION.
 INPUT-OUTPUT SECTION.
 FILE-CONTROL.
     SELECT CONTA-KSDS
         ASSIGN TO CONTA
         ORGANIZATION IS INDEXED
         ACCESS MODE IS SEQUENTIAL
         RECORD KEY IS CNT-CHAVE OF CONTA-REG
         FILE STATUS IS WS-FS-CONTA.

     SELECT SALDO-OUT
         ASSIGN TO SALDOUT
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-SALDO.

     SELECT AUDIT-OUT
         ASSIGN TO AUDIT
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-AUDIT.

 DATA DIVISION.
 FILE SECTION.
 FD  CONTA-KSDS.
 01  CONTA-REG.
     COPY CPCNT001.

 FD  SALDO-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  SALDO-REG.
     COPY CPSNP001.

 FD  AUDIT-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  AUDIT-REG.
     COPY CPAUD001.

 WORKING-STORAGE SECTION.
 01  WS-FILE-STATUS.
     05 WS-FS-CONTA            PIC XX VALUE SPACES.
        88 FS-CONTA-OK         VALUE '00'.
        88 FS-CONTA-EOF        VALUE '10'.
     05 WS-FS-SALDO            PIC XX VALUE SPACES.
        88 FS-SALDO-OK         VALUE '00'.
     05 WS-FS-AUDIT            PIC XX VALUE SPACES.
        88 FS-AUDIT-OK         VALUE '00'.

 01  WS-FLAGS.
     05 WS-EOF-CONTA           PIC X VALUE 'N'.
        88 EOF-CONTA           VALUE 'S'.
     05 WS-ERRO                PIC X VALUE 'N'.
        88 COM-ERRO            VALUE 'S'.

 01  WS-CONTADORES.
     05 WS-CT-LIDAS            PIC 9(9) VALUE ZERO.
     05 WS-CT-GERADAS          PIC 9(9) VALUE ZERO.
 01  WS-TOTAL-SALDO            PIC S9(15)V99 VALUE ZERO.
 01  WS-DATA-SISTEMA           PIC 9(8).
 01  WS-HORA-SISTEMA           PIC 9(8).
 01  WS-CHAVE-REF              PIC X(20).

 PROCEDURE DIVISION.
 0000-PRINCIPAL.
     ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
     ACCEPT WS-HORA-SISTEMA FROM TIME
     PERFORM 1000-ABRIR
     IF NOT COM-ERRO
         PERFORM 2000-PROCESSAR
         PERFORM 3000-AUDITAR
     END-IF
     PERFORM 9000-FECHAR
     PERFORM 9100-RC
     GOBACK.

 1000-ABRIR.
     OPEN INPUT CONTA-KSDS
     IF NOT FS-CONTA-OK
         DISPLAY '*** EBSNAP01 ERRO OPEN CONTA - ' WS-FS-CONTA
         SET COM-ERRO TO TRUE
     END-IF

     IF NOT COM-ERRO
         OPEN OUTPUT SALDO-OUT
         IF NOT FS-SALDO-OK
             DISPLAY '*** EBSNAP01 ERRO OPEN SALDOUT - '
                     WS-FS-SALDO
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND AUDIT-OUT
         IF NOT FS-AUDIT-OK
             DISPLAY '*** EBSNAP01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
             SET COM-ERRO TO TRUE
         END-IF
     END-IF.

 2000-PROCESSAR.
     PERFORM UNTIL EOF-CONTA OR COM-ERRO
         READ CONTA-KSDS NEXT
             AT END
                 SET EOF-CONTA TO TRUE
             NOT AT END
                 IF FS-CONTA-OK
                     ADD 1 TO WS-CT-LIDAS
                     MOVE CNT-AGENCIA   OF CONTA-REG TO SNP-AGENCIA
                     MOVE CNT-NUM-CONTA OF CONTA-REG TO SNP-NUM-CONTA
                     MOVE CNT-SALDO     OF CONTA-REG TO SNP-SALDO
                     MOVE WS-DATA-SISTEMA            TO SNP-DATA
                     WRITE SALDO-REG
                     IF FS-SALDO-OK
                         ADD 1 TO WS-CT-GERADAS
                         ADD CNT-SALDO OF CONTA-REG TO WS-TOTAL-SALDO
                     ELSE
                         DISPLAY '*** EBSNAP01 ERRO WRITE SALDOUT - '
                                 WS-FS-SALDO
                         SET COM-ERRO TO TRUE
                     END-IF
                 ELSE
                     DISPLAY '*** EBSNAP01 ERRO READ CONTA - '
                             WS-FS-CONTA
                     SET COM-ERRO TO TRUE
                 END-IF
         END-READ
     END-PERFORM.

 3000-AUDITAR.
     MOVE SPACES TO AUDIT-REG
     MOVE 'OK'       TO AU-TIPO-EVENTO
     MOVE 'EBSNAP01' TO AU-PROGRAMA
     MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
     MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
     MOVE 'SNAPOK001' TO AU-COD-EVENTO
     MOVE 'SNAPSHOT-DIARIO' TO AU-CHAVE-REF
     MOVE 'SNAPSHOT DE SALDO GERADO' TO AU-MENSAGEM
     MOVE WS-CT-GERADAS TO AU-COMPLEMENTO
     WRITE AUDIT-REG.

 9000-FECHAR.
     CLOSE CONTA-KSDS SALDO-OUT AUDIT-OUT.

 9100-RC.
     DISPLAY '*** EBSNAP01 CONTAS LIDAS   : ' WS-CT-LIDAS
     DISPLAY '*** EBSNAP01 REGS GERADOS   : ' WS-CT-GERADAS
     DISPLAY '*** EBSNAP01 TOTAL DE SALDO : ' WS-TOTAL-SALDO
     IF COM-ERRO
         MOVE 8 TO RETURN-CODE
     ELSE
         MOVE 0 TO RETURN-CODE
     END-IF.
