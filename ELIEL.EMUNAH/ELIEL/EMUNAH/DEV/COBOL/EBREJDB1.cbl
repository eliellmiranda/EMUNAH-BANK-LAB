      *----------------------------------------------------------*
      * IDENTIFICATION DIVISION
      *----------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EBREJDB1.
       AUTHOR.        ELIEL.
      *----------------------------------------------------------*
      * EBREJDB1 - CARGA DE REJEITOS  VSAM -> DB2                *
      * PROJETO: EMUNAH-BANK-LAB                                  *
      *                                                            *
      * FUNCAO : LER SEQUENCIALMENTE ELIEL.EMUNAH.ARQ.REJEITOS.SEQ*
      *          E INSERIR OS REGISTROS NA TABELA DB2 EMUNAH.CDREJ *
      *                                                            *
      * MODELO : EBLCTDB1 (carga de lancamentos)                   *
      *                                                            *
      * PARTICULARIDADES:                                          *
      *   1. REJ-REGISTRO-ORIG (120 bytes) e redefinido como       *
      *      overlay de CPLCT001 para extrair os campos            *
      *   2. REJ_ID e IDENTITY — nao incluido no INSERT            *
      *   3. Sem FK — CDREJ e tabela de rejeitos denormalizada      *
      *   4. Sem SQLCODE -803 esperado na primeira carga           *
      *----------------------------------------------------------*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REJEITO-FILE ASSIGN TO AS-REJSEQ
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-REJ-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  REJEITO-FILE.
       01  REJEITO-REG.
           COPY CPREJ001.

      *---------------------------------------------------------------*
      * MULTIPLOS 01s NO MESMO FD COMPARTILHAM A MESMA AREA DE MEMORIA*
      * (Implicit redefinition — REDEFINES proibido em 01 FILE SECTION)*
      *---------------------------------------------------------------*
       01  LANCTO-ORIG.
           05  LO-CHAVE-CONTA.
               10  LO-AGENCIA        PIC 9(04).
               10  LO-NUM-CONTA      PIC 9(08).
           05  LO-DATA               PIC 9(08).
           05  LO-TIPO               PIC X(01).
           05  LO-VALOR              PIC 9(11)V99.
           05  LO-HISTORICO          PIC X(30).
           05  LO-CANAL              PIC X(10).
           05  LO-LOTE               PIC 9(06).
           05  LO-NSEQ               PIC 9(06).
           05  LO-STATUS             PIC X(01).
           05  FILLER                PIC X(33).
           05  FILLER                PIC X(36). *> REJ-MOTIVO(18)+
                                                *> REJ-TIMESTAMP(14)+
                                                *> REJ-ORIGEM(4)

       WORKING-STORAGE SECTION.

       01  WS-REJ-FILE-STATUS        PIC XX VALUE SPACES.
           88  WS-REJ-OK             VALUE '00'.

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
           05  HV-REJ-AGENCIA        PIC S9(9)     COMP.
           05  HV-REJ-NUM-CONTA      PIC S9(9)     COMP.
           05  HV-REJ-DATA-LANCTO    PIC X(10).
           05  HV-REJ-TIPO           PIC X(01).
           05  HV-REJ-VALOR          PIC S9(11)V99 COMP-3.
           05  HV-REJ-LOTE           PIC S9(6)     COMP-3.
           05  HV-REJ-NSEQ           PIC S9(6)     COMP-3.
           05  HV-REJ-COD-MOTIVO     PIC X(04).
           05  HV-REJ-TXT-MOTIVO     PIC X(14).
           05  HV-REJ-TIMESTAMP      PIC X(14).
           05  HV-REJ-ORIGEM         PIC X(04).
           EXEC SQL END DECLARE SECTION END-EXEC.

       01  WS-SQLCODE-ED         PIC -9(9).

      *----------------------------------------------------------*
      * PROCEDURE DIVISION
      *----------------------------------------------------------*
       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR-REJEITOS UNTIL FIM-VSAM
           PERFORM 3000-FINALIZAR
           GOBACK.

       1000-INICIALIZAR.
           DISPLAY 'EBREJDB1 - INICIO DA CARGA REJEITOS VSAM->DB2'

           OPEN INPUT REJEITO-FILE

           IF NOT WS-REJ-OK
               DISPLAY 'ERRO AO ABRIR VSAM REJEITO-FILE. STATUS='
                       WS-REJ-FILE-STATUS
               MOVE 16 TO RETURN-CODE
               GOBACK
           END-IF

           PERFORM 2100-LER-REJEITO.

       2000-PROCESSAR-REJEITOS.
           ADD 1 TO WS-QT-LIDOS

      *    Valida o registro antes de processar
           IF REJ-COD-MOTIVO = SPACES
               DISPLAY 'REGISTRO INVALIDO IGNORADO.'
           ELSE
               PERFORM 2200-CONVERTER-CAMPOS
               PERFORM 2300-INSERIR-REJEITO-DB2
           END-IF

      *    Le o proximo registro
           PERFORM 2100-LER-REJEITO.

       2100-LER-REJEITO.
           READ REJEITO-FILE NEXT RECORD
               AT END
                   SET FIM-VSAM TO TRUE
           END-READ

           IF NOT FIM-VSAM
               IF NOT WS-REJ-OK
                   DISPLAY 'ERRO DE LEITURA VSAM. STATUS='
                           WS-REJ-FILE-STATUS
                   PERFORM 9100-ROLLBACK-E-SAIR
               END-IF
           END-IF.

       2200-CONVERTER-CAMPOS.
      *    EXTRAI CAMPOS DO LANCAMENTO ORIGINAL VIA OVERLAY
           MOVE LO-AGENCIA         TO HV-REJ-AGENCIA
           MOVE LO-NUM-CONTA       TO HV-REJ-NUM-CONTA

      *    CONVERTE AAAAMMDD -> AAAA-MM-DD
           STRING LO-DATA(1:4) '-'
                  LO-DATA(5:2) '-'
                  LO-DATA(7:2)
               DELIMITED BY SIZE
               INTO HV-REJ-DATA-LANCTO
           END-STRING

           MOVE LO-TIPO            TO HV-REJ-TIPO
           MOVE LO-VALOR           TO HV-REJ-VALOR
           MOVE LO-LOTE            TO HV-REJ-LOTE
           MOVE LO-NSEQ            TO HV-REJ-NSEQ

      *    CAMPOS DE REJEICAO
           MOVE REJ-COD-MOTIVO     TO HV-REJ-COD-MOTIVO
           MOVE REJ-TXT-MOTIVO     TO HV-REJ-TXT-MOTIVO
           MOVE REJ-TIMESTAMP      TO HV-REJ-TIMESTAMP
           MOVE REJ-ORIGEM         TO HV-REJ-ORIGEM.

       2300-INSERIR-REJEITO-DB2.
      *    REJ_ID NAO E INCLUIDO — E IDENTITY (GERADO PELO DB2)
           EXEC SQL
               INSERT INTO EMUNAH.CDREJ
                   ( REJ_AGENCIA,      REJ_NUM_CONTA,
                     REJ_DATA_LANCTO,  REJ_TIPO,
                     REJ_VALOR,        REJ_LOTE,
                     REJ_NSEQ,         REJ_COD_MOTIVO,
                     REJ_TXT_MOTIVO,   REJ_TIMESTAMP,
                     REJ_ORIGEM )
               VALUES
                   ( :HV-REJ-AGENCIA,  :HV-REJ-NUM-CONTA,
                     :HV-REJ-DATA-LANCTO, :HV-REJ-TIPO,
                     :HV-REJ-VALOR,    :HV-REJ-LOTE,
                     :HV-REJ-NSEQ,     :HV-REJ-COD-MOTIVO,
                     :HV-REJ-TXT-MOTIVO,:HV-REJ-TIMESTAMP,
                     :HV-REJ-ORIGEM )
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-QT-INSERIDOS
                   PERFORM 2400-CONTROLAR-COMMIT
               WHEN -803
                   ADD 1 TO WS-QT-DUPLICADOS
                   DISPLAY 'REJEITO DUPLICADO. LOTE=' HV-REJ-LOTE
                           ' NSEQ=' HV-REJ-NSEQ ' - IGNORADO'
               WHEN OTHER
                   ADD 1 TO WS-QT-ERROS
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   DISPLAY 'ERRO SQL NO INSERT. SQLCODE='
                           WS-SQLCODE-ED
                           ' LOTE=' HV-REJ-LOTE
                           ' NSEQ=' HV-REJ-NSEQ
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
           CLOSE REJEITO-FILE

           DISPLAY '-------------------------------------------'
           DISPLAY 'EBREJDB1 - RESUMO DA CARGA'
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
           CLOSE REJEITO-FILE
           MOVE 16 TO RETURN-CODE
           GOBACK.
