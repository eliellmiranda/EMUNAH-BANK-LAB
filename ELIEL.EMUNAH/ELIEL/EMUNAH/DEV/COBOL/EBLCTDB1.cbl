      *----------------------------------------------------------*
      * IDENTIFICATION DIVISION
      *----------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EBLCTDB1.
       AUTHOR.        ELIEL.
      *----------------------------------------------------------*
      * EBLCTDB1 - CARGA DE LANCAMENTOS  VSAM -> DB2             *
      * PROJETO: EMUNAH-BANK-LAB                                  *
      *                                                            *
      * FUNCAO : LER SEQUENCIALMENTE O VSAM ESDS                  *
      *          ELIEL.EMUNAH.ARQ.LANCTO.ESDS E INSERIR OS        *
      *          REGISTROS NA TABELA DB2 EMUNAH.CDLCT             *
      *                                                            *
      * MODELO : EBCNTDB1 (carga de contas)                        *
      *                                                            *
      * DIFERENCAS EM RELACAO AO EBCNTDB1:                         *
      *   1. ESDS (sem chave) — ORGANIZATION IS SEQUENTIAL         *
      *   2. PK composta: LCT_LOTE + LCT_NSEQ (DECIMAL 6,0)       *
      *   3. FK aponta para CDCNT (nao CDCLI)                      *
      *   4. LCT-VALOR PIC 9(11)V99 unsigned -> COMP-3 signed      *
      *----------------------------------------------------------*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LANCTO-FILE ASSIGN TO AS-LCTESDS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-LCT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  LANCTO-FILE.
       01  LANCTO-REG.
           COPY CPLCT001.

       WORKING-STORAGE SECTION.

       01  WS-LCT-FILE-STATUS        PIC XX VALUE SPACES.
           88  WS-LCT-OK             VALUE '00'.

       01  WS-FLAGS.
           05  WS-EOF-VSAM           PIC X VALUE 'N'.
               88  FIM-VSAM          VALUE 'S'.

       01  WS-CONTADORES.
           05  WS-QT-LIDOS           PIC 9(9) VALUE 0.
           05  WS-QT-INSERIDOS       PIC 9(9) VALUE 0.
           05  WS-QT-DUPLICADOS      PIC 9(9) VALUE 0.
           05  WS-QT-ERROS           PIC 9(9) VALUE 0.

       01  WS-COMMIT-CONTROLE.
           05  WS-COMMIT-CONT        PIC 9(9) VALUE 0.
           05  WS-COMMIT-FREQ        PIC 9(9) VALUE 100.

           EXEC SQL INCLUDE SQLCA END-EXEC.

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  WS-HOST-VARS.
           05  HV-LCT-AGENCIA        PIC S9(9)    COMP.
           05  HV-LCT-NUM-CONTA      PIC S9(9)    COMP.
           05  HV-LCT-DATA           PIC X(10).
           05  HV-LCT-TIPO           PIC X(01).
           05  HV-LCT-VALOR          PIC S9(11)V99 COMP-3.
           05  HV-LCT-HISTORICO      PIC X(30).
           05  HV-LCT-CANAL          PIC X(10).
           05  HV-LCT-LOTE           PIC S9(6)    COMP-3.
           05  HV-LCT-NSEQ           PIC S9(6)    COMP-3.
           05  HV-LCT-STATUS         PIC X(01).
           EXEC SQL END DECLARE SECTION END-EXEC.

       01  WS-SQLCODE-ED         PIC -9(9).

      *----------------------------------------------------------*
      * PROCEDURE DIVISION
      *----------------------------------------------------------*
       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR-LANCTOS UNTIL FIM-VSAM
           PERFORM 3000-FINALIZAR
           GOBACK.

       1000-INICIALIZAR.
           DISPLAY 'EBLCTDB1 - INICIO DA CARGA LANCAMENTOS VSAM->DB2'

           OPEN INPUT LANCTO-FILE

           IF NOT WS-LCT-OK
               DISPLAY 'ERRO AO ABRIR VSAM LANCTO-FILE. STATUS='
                       WS-LCT-FILE-STATUS
               MOVE 16 TO RETURN-CODE
               GOBACK
           END-IF

           PERFORM 2100-LER-LANCTO.

       2000-PROCESSAR-LANCTOS.
           ADD 1 TO WS-QT-LIDOS
           PERFORM 2200-CONVERTER-CAMPOS
           PERFORM 2300-INSERIR-LANCTO-DB2
           PERFORM 2100-LER-LANCTO.

       2100-LER-LANCTO.
           READ LANCTO-FILE NEXT RECORD
               AT END
                   SET FIM-VSAM TO TRUE
           END-READ

           IF NOT FIM-VSAM
               IF NOT WS-LCT-OK
                   DISPLAY 'ERRO DE LEITURA VSAM. STATUS='
                           WS-LCT-FILE-STATUS
                   PERFORM 9100-ROLLBACK-E-SAIR
               END-IF
           END-IF

           IF NOT FIM-VSAM
               IF LCT-LOTE = ZEROS AND LCT-NSEQ = ZEROS
                   DISPLAY 'REGISTRO INVALIDO IGNORADO. LOTE='
                           LCT-LOTE
                   PERFORM 2100-LER-LANCTO
               END-IF
           END-IF.

       2200-CONVERTER-CAMPOS.
      *    PIC 9(n) DISPLAY -> PIC S9(9) COMP — MOVE direto
           MOVE LCT-AGENCIA        TO HV-LCT-AGENCIA
           MOVE LCT-NUM-CONTA      TO HV-LCT-NUM-CONTA

      *    CONVERTE AAAAMMDD (VSAM) PARA AAAA-MM-DD (DB2 DATE)
           STRING LCT-DATA(1:4) '-'
                  LCT-DATA(5:2) '-'
                  LCT-DATA(7:2)
               DELIMITED BY SIZE
               INTO HV-LCT-DATA
           END-STRING

           MOVE LCT-TIPO           TO HV-LCT-TIPO

      *    PIC 9(11)V99 unsigned -> PIC S9(11)V99 COMP-3
      *    COBOL sign-extends automatically
           MOVE LCT-VALOR          TO HV-LCT-VALOR

           MOVE LCT-HISTORICO      TO HV-LCT-HISTORICO
           MOVE LCT-CANAL          TO HV-LCT-CANAL

      *    PIC 9(6) DISPLAY -> PIC S9(6) COMP-3 — MOVE direto
           MOVE LCT-LOTE           TO HV-LCT-LOTE
           MOVE LCT-NSEQ           TO HV-LCT-NSEQ

           MOVE LCT-STATUS         TO HV-LCT-STATUS.

       2300-INSERIR-LANCTO-DB2.
           EXEC SQL
               INSERT INTO EMUNAH.CDLCT
                   ( LCT_AGENCIA,    LCT_NUM_CONTA,
                     LCT_DATA,       LCT_TIPO,
                     LCT_VALOR,      LCT_HISTORICO,
                     LCT_CANAL,      LCT_LOTE,
                     LCT_NSEQ,       LCT_STATUS )
               VALUES
                   ( :HV-LCT-AGENCIA,  :HV-LCT-NUM-CONTA,
                     :HV-LCT-DATA,     :HV-LCT-TIPO,
                     :HV-LCT-VALOR,    :HV-LCT-HISTORICO,
                     :HV-LCT-CANAL,    :HV-LCT-LOTE,
                     :HV-LCT-NSEQ,     :HV-LCT-STATUS )
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-QT-INSERIDOS
                   PERFORM 2400-CONTROLAR-COMMIT
               WHEN -803
                   ADD 1 TO WS-QT-DUPLICADOS
                   DISPLAY 'LANCTO DUPLICADO. LOTE=' HV-LCT-LOTE
                           ' NSEQ=' HV-LCT-NSEQ ' - IGNORADO'
               WHEN -530
      *            FK VIOLATION: CONTA NAO EXISTE EM CDCNT
      *            REGISTRA ERRO MAS NAO FAZ ROLLBACK — CONTINUA
                   ADD 1 TO WS-QT-ERROS
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   DISPLAY 'FK VIOLATION -530. AG=' HV-LCT-AGENCIA
                           ' CT=' HV-LCT-NUM-CONTA
                           ' NAO EXISTE EM CDCNT. LANCTO REJEITADO.'
                   DISPLAY 'SQLERRMC: ' SQLERRMC
               WHEN OTHER
                   ADD 1 TO WS-QT-ERROS
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   DISPLAY 'ERRO SQL NO INSERT. SQLCODE='
                           WS-SQLCODE-ED
                           ' LOTE=' HV-LCT-LOTE
                           ' NSEQ=' HV-LCT-NSEQ
                   DISPLAY 'SQLERRMC: ' SQLERRMC
                   PERFORM 9100-ROLLBACK-E-SAIR
           END-EVALUATE.

       2400-CONTROLAR-COMMIT.
           ADD 1 TO WS-COMMIT-CONT
           IF WS-COMMIT-CONT >= WS-COMMIT-FREQ
               EXEC SQL COMMIT END-EXEC
               MOVE 0 TO WS-COMMIT-CONT
               DISPLAY 'COMMIT REALIZADO. INSERIDOS ATE AGORA: '
                       WS-QT-INSERIDOS
           END-IF.

       3000-FINALIZAR.
           EXEC SQL COMMIT END-EXEC
           CLOSE LANCTO-FILE

           DISPLAY '-------------------------------------------'
           DISPLAY 'EBLCTDB1 - RESUMO DA CARGA'
           DISPLAY 'REGISTROS LIDOS ......: ' WS-QT-LIDOS
           DISPLAY 'REGISTROS INSERIDOS ..: ' WS-QT-INSERIDOS
           DISPLAY 'DUPLICADOS (IGNORADOS): ' WS-QT-DUPLICADOS
           DISPLAY 'ERROS ................: ' WS-QT-ERROS
           DISPLAY '-------------------------------------------'

           IF WS-QT-ERROS > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.

       9100-ROLLBACK-E-SAIR.
           DISPLAY 'PROCESSAMENTO INTERROMPIDO POR ERRO.'
           EXEC SQL ROLLBACK END-EXEC
           CLOSE LANCTO-FILE
           MOVE 16 TO RETURN-CODE
           GOBACK.
