      *----------------------------------------------------------*
      * IDENTIFICATION DIVISION
      *----------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EBCNTDB1.
       AUTHOR.        ELIEL.
      *----------------------------------------------------------*
      * EBCNTDB1 - CARGA DE CONTAS  VSAM -> DB2                  *
      * PROJETO: EMUNAH-BANK-LAB                                  *
      *                                                            *
      * FUNCAO : LER SEQUENCIALMENTE O VSAM KSDS                  *
      *          ELIEL.EMUNAH.ARQ.CONTA.KSDS E INSERIR OS         *
      *          REGISTROS NA TABELA DB2 EMUNAH.CDCNT             *
      *                                                            *
      * MODELO : EBCLDB01 (carga de clientes)                      *
      *                                                            *
      * DIFERENCAS EM RELACAO AO EBCLDB01:                         *
      *   1. Chave composta (AGENCIA + NUM_CONTA) via NUMVAL        *
      *   2. COMP-3 para SALDO e LIMITE                             *
      *   3. SQLCODE -530 (FK violation) tratado sem ROLLBACK       *
      *----------------------------------------------------------*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CONTA-FILE ASSIGN TO CNTVSAM
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE
               FILE STATUS IS WS-CNT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CONTA-FILE.
       01  CONTA-REG.
           COPY CPCNT001.

       WORKING-STORAGE SECTION.

       01  WS-CNT-FILE-STATUS        PIC XX VALUE SPACES.
           88  WS-CNT-OK             VALUE '00'.

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
           05  HV-CNT-AGENCIA        PIC S9(9) COMP.
           05  HV-CNT-NUM-CONTA      PIC S9(9) COMP.
           05  HV-CNT-ID-CLIENTE     PIC S9(9) COMP.
           05  HV-CNT-TIPO           PIC X(01).
           05  HV-CNT-STATUS         PIC X(01).
           05  HV-CNT-DATA-ABERTURA  PIC X(10).
           05  HV-CNT-SALDO          PIC S9(11)V99 COMP-3.
           05  HV-CNT-LIMITE         PIC S9(9)V99  COMP-3.
           EXEC SQL END DECLARE SECTION END-EXEC.

       01  WS-SQLCODE-ED         PIC -9(9).

      *----------------------------------------------------------*
      * PROCEDURE DIVISION
      *----------------------------------------------------------*
       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR-CONTAS UNTIL FIM-VSAM
           PERFORM 3000-FINALIZAR
           GOBACK.

       1000-INICIALIZAR.
           DISPLAY 'EBCNTDB01 - INICIO DA CARGA CONTAS VSAM -> DB2'

           OPEN INPUT CONTA-FILE

           IF NOT WS-CNT-OK
               DISPLAY 'ERRO AO ABRIR VSAM CONTA-FILE. STATUS='
                       WS-CNT-FILE-STATUS
               MOVE 16 TO RETURN-CODE
               GOBACK
           END-IF

           PERFORM 2100-LER-CONTA.

       2000-PROCESSAR-CONTAS.
           ADD 1 TO WS-QT-LIDOS
           PERFORM 2200-CONVERTER-CAMPOS
           PERFORM 2300-INSERIR-CONTA-DB2
           PERFORM 2100-LER-CONTA.

       2100-LER-CONTA.
           READ CONTA-FILE NEXT RECORD
               AT END
                   SET FIM-VSAM TO TRUE
           END-READ

           IF NOT FIM-VSAM
               IF NOT WS-CNT-OK
                   DISPLAY 'ERRO DE LEITURA VSAM. STATUS='
                           WS-CNT-FILE-STATUS
                   PERFORM 9100-ROLLBACK-E-SAIR
               END-IF
           END-IF

           IF NOT FIM-VSAM
               IF CNT-AGENCIA = ZEROS OR CNT-NUM-CONTA = ZEROS
                   DISPLAY 'REGISTRO INVALIDO IGNORADO. AG='
                           CNT-AGENCIA
                   PERFORM 2100-LER-CONTA
               END-IF
           END-IF.

       2200-CONVERTER-CAMPOS.
      *    PIC 9(n) DISPLAY -> PIC S9(9) COMP
      *    MOVE DIRETO FUNCIONA: COBOL converte DISPLAY->COMP binario
      *    NUMVAL e apenas para PIC X — nao aplicavel aqui
           MOVE CNT-AGENCIA            TO HV-CNT-AGENCIA
           MOVE CNT-NUM-CONTA          TO HV-CNT-NUM-CONTA
           MOVE CNT-ID-CLIENTE         TO HV-CNT-ID-CLIENTE

           MOVE CNT-TIPO           TO HV-CNT-TIPO
           MOVE CNT-STATUS         TO HV-CNT-STATUS

      *    CONVERTE AAAAMMDD (VSAM) PARA AAAA-MM-DD (DB2 DATE)
           STRING CNT-DATA-ABERTURA(1:4) '-'
                  CNT-DATA-ABERTURA(5:2) '-'
                  CNT-DATA-ABERTURA(7:2)
               DELIMITED BY SIZE
               INTO HV-CNT-DATA-ABERTURA
           END-STRING

      *    COMP-3: MOVE DIRETO FUNCIONA — COBOL CONVERTE
      *    DISPLAY/ZONED -> PACKED AUTOMATICAMENTE
           MOVE CNT-SALDO          TO HV-CNT-SALDO
           MOVE CNT-LIMITE         TO HV-CNT-LIMITE.

       2300-INSERIR-CONTA-DB2.
           EXEC SQL
               INSERT INTO EMUNAH.CDCNT
                   ( CNT_AGENCIA,       CNT_NUM_CONTA,
                     CNT_ID_CLIENTE,    CNT_TIPO,
                     CNT_STATUS,        CNT_DATA_ABERTURA,
                     CNT_SALDO,         CNT_LIMITE )
               VALUES
                   ( :HV-CNT-AGENCIA,   :HV-CNT-NUM-CONTA,
                     :HV-CNT-ID-CLIENTE,:HV-CNT-TIPO,
                     :HV-CNT-STATUS,    :HV-CNT-DATA-ABERTURA,
                     :HV-CNT-SALDO,     :HV-CNT-LIMITE )
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-QT-INSERIDOS
                   PERFORM 2400-CONTROLAR-COMMIT
               WHEN -803
                   ADD 1 TO WS-QT-DUPLICADOS
                   DISPLAY 'CONTA DUPLICADA, AG=' HV-CNT-AGENCIA
                           ' CT=' HV-CNT-NUM-CONTA ' - IGNORADA'
               WHEN -530
      *            FK VIOLATION: CNT_ID_CLIENTE NAO EXISTE EM CDCLI
      *            REGISTRA ERRO MAS NAO FAZ ROLLBACK — CONTINUA
                   ADD 1 TO WS-QT-ERROS
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   DISPLAY 'FK VIOLATION -530. CLIENTE='
                           HV-CNT-ID-CLIENTE
                           ' NAO EXISTE EM CDCLI. CONTA REJEITADA.'
                   DISPLAY 'SQLERRMC: ' SQLERRMC
               WHEN OTHER
                   ADD 1 TO WS-QT-ERROS
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   DISPLAY 'ERRO SQL NO INSERT. SQLCODE='
                           WS-SQLCODE-ED
                           ' AG=' HV-CNT-AGENCIA
                           ' CT=' HV-CNT-NUM-CONTA
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
           CLOSE CONTA-FILE

           DISPLAY '-------------------------------------------'
           DISPLAY 'EBCNTDB01 - RESUMO DA CARGA'
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
           CLOSE CONTA-FILE
           MOVE 16 TO RETURN-CODE
           GOBACK.
