      *----------------------------------------------------------*
      * IDENTIFICATION DIVISION
      *----------------------------------------------------------*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EBCLDB01.
       AUTHOR.        ELIEL.
      *----------------------------------------------------------*
      * EBCLDB01 - CARGA DE CLIENTES  VSAM -> DB2                 *
      * PROJETO: EMUNAH-BANK-LAB                                  *
      *                                                            *
      * FUNCAO : LER SEQUENCIALMENTE O VSAM KSDS                  *
      *          ELIEL.EMUNAH.ARQ.CLIENTE.KSDS E INSERIR OS       *
      *          REGISTROS NA TABELA DB2 EMUNAH.CLIENTES          *
      *                                                            *
      * OBS    : LAYOUT DE CPCLI001 CONFIRMADO PELO USUARIO.      *
      *          COLUNAS DA TABELA DB2 AINDA SAO ASSUMIDAS -      *
      *          CONFIRA CONTRA O CREATE TABLE REAL.              *
      *----------------------------------------------------------*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CLIENTE-FILE ASSIGN TO CLIVSAM
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CLI-ID-CLIENTE
               FILE STATUS IS WS-CLI-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CLIENTE-FILE.
       01  CLIENTE-REG.
           COPY CPCLI001.

       WORKING-STORAGE SECTION.

       01  WS-CLI-FILE-STATUS        PIC XX VALUE SPACES.
           88  WS-CLI-OK             VALUE '00'.

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
           05  HV-CLI-ID-CLIENTE     PIC S9(9) COMP.
           05  HV-CLI-NOME           PIC X(30).
           05  HV-CLI-CPF            PIC X(11).
           05  HV-CLI-DATA-NASC      PIC X(10).
           05  HV-CLI-STATUS         PIC X(01).
           05  HV-CLI-DATA-CAD       PIC X(10).
           EXEC SQL END DECLARE SECTION END-EXEC.

      *----------------------------------------------------------*
      * PROCEDURE DIVISION
      *----------------------------------------------------------*
       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR-CLIENTES UNTIL FIM-VSAM
           PERFORM 3000-FINALIZAR
           GOBACK.

       1000-INICIALIZAR.
           DISPLAY 'EBCLDB01 - INICIO DA CARGA CLIENTES VSAM -> DB2'

           OPEN INPUT CLIENTE-FILE

           IF NOT WS-CLI-OK
               DISPLAY 'ERRO AO ABRIR VSAM CLIENTE-FILE. STATUS='
                       WS-CLI-FILE-STATUS
               MOVE 16 TO RETURN-CODE
               GOBACK
           END-IF

           PERFORM 2100-LER-CLIENTE.

       2000-PROCESSAR-CLIENTES.
           ADD 1 TO WS-QT-LIDOS
           PERFORM 2200-CONVERTER-CAMPOS
           PERFORM 2300-INSERIR-CLIENTE-DB2
           PERFORM 2100-LER-CLIENTE.

       2100-LER-CLIENTE.
           READ CLIENTE-FILE NEXT RECORD
               AT END
                   SET FIM-VSAM TO TRUE
           END-READ

           IF NOT FIM-VSAM
               IF NOT WS-CLI-OK
                   DISPLAY 'ERRO DE LEITURA VSAM. STATUS='
                           WS-CLI-FILE-STATUS
                   PERFORM 9100-ROLLBACK-E-SAIR
               END-IF
           END-IF.

       2200-CONVERTER-CAMPOS.
           MOVE CLI-ID-CLIENTE  TO HV-CLI-ID-CLIENTE
           MOVE CLI-NOME        TO HV-CLI-NOME
           MOVE CLI-CPF         TO HV-CLI-CPF
           MOVE CLI-STATUS      TO HV-CLI-STATUS

      *    CONVERTE AAAAMMDD (VSAM) PARA AAAA-MM-DD (DB2 DATE)
           STRING CLI-DATA-NASC(1:4) '-'
                  CLI-DATA-NASC(5:2) '-'
                  CLI-DATA-NASC(7:2)
               DELIMITED BY SIZE
               INTO HV-CLI-DATA-NASC
           END-STRING

           STRING CLI-DATA-CAD(1:4) '-'
                  CLI-DATA-CAD(5:2) '-'
                  CLI-DATA-CAD(7:2)
               DELIMITED BY SIZE
               INTO HV-CLI-DATA-CAD
           END-STRING.

       2300-INSERIR-CLIENTE-DB2.
           EXEC SQL
               INSERT INTO EMUNAH.CLIENTES
                   ( CLI_ID_CLIENTE, CLI_NOME,     CLI_CPF,
                     CLI_DATA_NASC,  CLI_STATUS,   CLI_DATA_CAD )
               VALUES
                   ( :HV-CLI-ID-CLIENTE, :HV-CLI-NOME, :HV-CLI-CPF,
                     :HV-CLI-DATA-NASC, :HV-CLI-STATUS,
                     :HV-CLI-DATA-CAD )
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-QT-INSERIDOS
                   PERFORM 2400-CONTROLAR-COMMIT
               WHEN -803
                   ADD 1 TO WS-QT-DUPLICADOS
                   DISPLAY 'CLIENTE DUPLICADO, ID='
                           HV-CLI-ID-CLIENTE ' - IGNORADO'
               WHEN OTHER
                   ADD 1 TO WS-QT-ERROS
                   DISPLAY 'ERRO SQL NO INSERT. SQLCODE='
                           SQLCODE ' CLIENTE=' HV-CLI-ID-CLIENTE
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
           CLOSE CLIENTE-FILE

           DISPLAY '-------------------------------------------'
           DISPLAY 'EBCLDB01 - RESUMO DA CARGA'
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
           CLOSE CLIENTE-FILE
           MOVE 16 TO RETURN-CODE
           GOBACK.
