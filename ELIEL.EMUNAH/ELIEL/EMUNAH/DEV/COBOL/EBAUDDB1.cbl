      *----------------------------------------------------------*
      * IDENTIFICATION DIVISION
      *----------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EBAUDDB1.
       AUTHOR.        ELIEL.
      *----------------------------------------------------------*
      * EBAUDDB1 - CARGA DE AUDITORIA  VSAM -> DB2               *
      * PROJETO: EMUNAH-BANK-LAB                                  *
      *                                                            *
      * FUNCAO : LER SEQUENCIALMENTE ELIEL.EMUNAH.ARQ.AUDIT.SEQ   *
      *          E INSERIR OS REGISTROS NA TABELA DB2 EMUNAH.CDAUD *
      *                                                            *
      * MODELO : EBLCTDB1 (carga de lancamentos)                   *
      *                                                            *
      * PARTICULARIDADES:                                          *
      *   1. AUD_ID e IDENTITY — nao incluido no INSERT            *
      *   2. Sem FK — CDAUD e append-only, sem referencia          *
      *   3. AU-DATA-EVENTO PIC 9(8) -> DATE via STRING            *
      *   4. AU-HORA-EVENTO PIC 9(6) -> CHAR(6) via MOVE direto    *
      *   5. AUD_TIMESTAMP nullable — preenchido pelo programa      *
      *      com CURRENT TIMESTAMP via SQL scalar function          *
      *----------------------------------------------------------*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT AUDIT-FILE ASSIGN TO AS-AUDSEQ
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-AUD-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  AUDIT-FILE.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

       01  WS-AUD-FILE-STATUS        PIC XX VALUE SPACES.
           88  WS-AUD-OK             VALUE '00'.

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
           05  HV-AU-TIPO-EVENTO     PIC X(04).
           05  HV-AU-PROGRAMA        PIC X(08).
           05  HV-AU-DATA-EVENTO     PIC X(10).
           05  HV-AU-HORA-EVENTO     PIC X(06).
           05  HV-AU-COD-EVENTO      PIC X(10).
           05  HV-AU-CHAVE-REF       PIC X(20).
           05  HV-AU-MENSAGEM        PIC X(54).
           05  HV-AU-COMPLEMENTO     PIC X(10).
           EXEC SQL END DECLARE SECTION END-EXEC.

       01  WS-SQLCODE-ED         PIC -9(9).

      *----------------------------------------------------------*
      * PROCEDURE DIVISION
      *----------------------------------------------------------*
       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR-AUDITS UNTIL FIM-VSAM
           PERFORM 3000-FINALIZAR
           GOBACK.

       1000-INICIALIZAR.
           DISPLAY 'EBAUDDB1 - INICIO DA CARGA AUDITORIA VSAM->DB2'

           OPEN INPUT AUDIT-FILE

           IF NOT WS-AUD-OK
               DISPLAY 'ERRO AO ABRIR VSAM AUDIT-FILE. STATUS='
                       WS-AUD-FILE-STATUS
               MOVE 16 TO RETURN-CODE
               GOBACK
           END-IF

           PERFORM 2100-LER-AUDIT.

       2000-PROCESSAR-AUDITS.
           ADD 1 TO WS-QT-LIDOS
           PERFORM 2200-CONVERTER-CAMPOS
           PERFORM 2300-INSERIR-AUDIT-DB2
           PERFORM 2100-LER-AUDIT.

       2100-LER-AUDIT.
           READ AUDIT-FILE NEXT RECORD
               AT END
                   SET FIM-VSAM TO TRUE
           END-READ

           IF NOT FIM-VSAM
               IF NOT WS-AUD-OK
                   DISPLAY 'ERRO DE LEITURA VSAM. STATUS='
                           WS-AUD-FILE-STATUS
                   PERFORM 9100-ROLLBACK-E-SAIR
               END-IF
           END-IF

           IF NOT FIM-VSAM
               IF AU-PROGRAMA = SPACES
                   DISPLAY 'REGISTRO INVALIDO IGNORADO.'
                   PERFORM 2100-LER-AUDIT
               END-IF
           END-IF.

       2200-CONVERTER-CAMPOS.
           MOVE AU-TIPO-EVENTO      TO HV-AU-TIPO-EVENTO
           MOVE AU-PROGRAMA         TO HV-AU-PROGRAMA

      *    CONVERTE AAAAMMDD (PIC 9(8)) -> AAAA-MM-DD (DATE)
           STRING AU-DATA-EVENTO(1:4) '-'
                  AU-DATA-EVENTO(5:2) '-'
                  AU-DATA-EVENTO(7:2)
               DELIMITED BY SIZE
               INTO HV-AU-DATA-EVENTO
           END-STRING

      *    HORA: PIC 9(6) DISPLAY -> PIC X(06) CHAR — MOVE direto
           MOVE AU-HORA-EVENTO      TO HV-AU-HORA-EVENTO

           MOVE AU-COD-EVENTO       TO HV-AU-COD-EVENTO
           MOVE AU-CHAVE-REF        TO HV-AU-CHAVE-REF
           MOVE AU-MENSAGEM         TO HV-AU-MENSAGEM
           MOVE AU-COMPLEMENTO      TO HV-AU-COMPLEMENTO.

       2300-INSERIR-AUDIT-DB2.
      *    AUD_ID NAO E INCLUIDO — E IDENTITY (GERADO PELO DB2)
      *    AUD_TIMESTAMP omitido — coluna e nullable, DB2 aceita NULL
           EXEC SQL
               INSERT INTO EMUNAH.CDAUD
                   ( AU_TIPO_EVENTO,  AU_PROGRAMA,
                     AU_DATA_EVENTO,  AU_HORA_EVENTO,
                     AU_COD_EVENTO,   AU_CHAVE_REF,
                     AU_MENSAGEM,     AU_COMPLEMENTO )
               VALUES
                   ( :HV-AU-TIPO-EVENTO, :HV-AU-PROGRAMA,
                     :HV-AU-DATA-EVENTO, :HV-AU-HORA-EVENTO,
                     :HV-AU-COD-EVENTO,  :HV-AU-CHAVE-REF,
                     :HV-AU-MENSAGEM,    :HV-AU-COMPLEMENTO )
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-QT-INSERIDOS
                   PERFORM 2400-CONTROLAR-COMMIT
               WHEN OTHER
                   ADD 1 TO WS-QT-ERROS
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   DISPLAY 'ERRO SQL NO INSERT. SQLCODE='
                           WS-SQLCODE-ED
                           ' PROG=' HV-AU-PROGRAMA
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
           CLOSE AUDIT-FILE

           DISPLAY '-------------------------------------------'
           DISPLAY 'EBAUDDB1 - RESUMO DA CARGA'
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
           CLOSE AUDIT-FILE
           MOVE 16 TO RETURN-CODE
           GOBACK.
