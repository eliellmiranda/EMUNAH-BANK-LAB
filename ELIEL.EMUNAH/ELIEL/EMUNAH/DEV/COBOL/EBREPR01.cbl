       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBREPR01.
      *===============================================================*
      * PROGRAMA : EBREPR01                                           *
      * BIBLIOTECA: ELIEL.EMUNAH.BATCH.COBOL                         *
      * FUNCAO   : REPROCESSAMENTO DE LANCAMENTOS REJEITADOS          *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o arquivo sequencial de rejeitos gerado pelo EBVALI01    *
      * - Reaplica as 5 regras de validacao sobre cada registro       *
      * - Registros que passam voltam ao fluxo normal (LANCTO-OUT)    *
      * - Registros que falham sao mantidos no arquivo de rejeitos    *
      *   com motivo acumulado (separador ' | ')                      *
      * - Registra cada decisao no arquivo de auditoria               *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REJEIT-IN
               ASSIGN TO REJIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJIN.

           SELECT LANCTO-OUT
               ASSIGN TO LCTOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-LCTOUT.

           SELECT REJEIT-OUT
               ASSIGN TO REJOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJOUT.

           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

       FD  REJEIT-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-IN-RAW              PIC X(120).
       01  REJEIT-IN-REG.
           05 RJ-AGENCIA              PIC 9(4).
           05 RJ-NUM-CONTA            PIC 9(8).
           05 RJ-DATA                 PIC 9(8).
           05 RJ-TIPO                 PIC X(1).
           05 RJ-VALOR                PIC 9(11)V99.
           05 RJ-HISTORICO            PIC X(30).
           05 RJ-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

       FD  LANCTO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  LANCTO-OUT-REG.
           COPY CPLCT001.

       FD  REJEIT-OUT
           RECORD CONTAINS 150 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-OUT-REG.
           05 RO-DADOS-ORIG           PIC X(120).
           05 RO-MOTIVO               PIC X(30).

      *---------------------------------------------------------------*
      * Registro de auditoria - Envelopado para 128 bytes perfeitos   *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG-OUT.
           COPY CPAUD001.
           05 FILLER                  PIC X(8).

       WORKING-STORAGE SECTION.

       01  WS-FILE-STATUS.
           05 WS-FS-REJIN             PIC XX.
           05 WS-FS-LCTOUT            PIC XX.
           05 WS-FS-REJOUT            PIC XX.
           05 WS-FS-AUDIT             PIC XX.

       01  WS-CONTROLES.
           05 WS-EOF-REJIN            PIC X VALUE 'N'.
               88 FIM-REJIN           VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
               88 ERRO-IO-DETECTADO   VALUE 'S'.

       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(5) VALUE ZERO.
           05 WS-RECUPERADOS          PIC 9(5) VALUE ZERO.
           05 WS-MANTIDOS-REJ         PIC 9(5) VALUE ZERO.

       01  WS-MOTIVO-ACUM             PIC X(120) VALUE SPACES.
       01  WS-MOTIVO-TEMP             PIC X(30)  VALUE SPACES.

       01  WS-FLAGS-VALID.
           05 WS-TIPO-VALIDO          PIC X VALUE 'S'.
               88 TIPO-INVALIDO       VALUE 'N'.
           05 WS-AG-VALIDA            PIC X VALUE 'S'.
               88 AG-INVALIDA         VALUE 'N'.
           05 WS-CT-VALIDA            PIC X VALUE 'S'.
               88 CT-INVALIDA         VALUE 'N'.
           05 WS-VALOR-VALIDO         PIC X VALUE 'S'.
               88 VALOR-INVALIDO      VALUE 'N'.
           05 WS-DATA-VALIDA          PIC X VALUE 'S'.
               88 DATA-INVALIDA       VALUE 'N'.

       01  WS-DATA-PROC               PIC X(8).
       01  WS-HORA-PROC               PIC X(8).

       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           ACCEPT WS-DATA-PROC FROM DATE YYYYMMDD
           ACCEPT WS-HORA-PROC FROM TIME

           PERFORM 1000-ABRIR-ARQUIVOS
           IF NOT ERRO-IO-DETECTADO
               PERFORM 2000-REPROCESSAR-REJEITOS
               PERFORM 9000-ENCERRAR
           ELSE
               MOVE 12 TO RETURN-CODE
           END-IF

           GOBACK.

       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  REJEIT-IN
           IF WS-FS-REJIN NOT = '00'
               DISPLAY 'ERRO OPEN REJEIT-IN FS=' WS-FS-REJIN
               MOVE 'S' TO WS-ERRO-IO
               EXIT PARAGRAPH
           END-IF

           OPEN OUTPUT LANCTO-OUT
           IF WS-FS-LCTOUT NOT = '00'
               DISPLAY 'ERRO OPEN LANCTO-OUT FS=' WS-FS-LCTOUT
               MOVE 'S' TO WS-ERRO-IO
               EXIT PARAGRAPH
           END-IF

           OPEN OUTPUT REJEIT-OUT
           IF WS-FS-REJOUT NOT = '00'
               DISPLAY 'ERRO OPEN REJEIT-OUT FS=' WS-FS-REJOUT
               MOVE 'S' TO WS-ERRO-IO
               EXIT PARAGRAPH
           END-IF

           OPEN EXTEND AUDIT-OUT
           IF WS-FS-AUDIT NOT = '00'
               DISPLAY 'ERRO OPEN AUDIT-OUT FS=' WS-FS-AUDIT
               MOVE 'S' TO WS-ERRO-IO
               EXIT PARAGRAPH
           END-IF.

       2000-REPROCESSAR-REJEITOS.
           PERFORM UNTIL FIM-REJIN
               READ REJEIT-IN
                   AT END
                       MOVE 'S' TO WS-EOF-REJIN
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       PERFORM 2100-VALIDAR-REGISTRO
               END-READ
           END-PERFORM.

       2100-VALIDAR-REGISTRO.
           MOVE SPACES TO WS-MOTIVO-ACUM
           MOVE 'S'    TO WS-TIPO-VALIDO
           MOVE 'S'    TO WS-AG-VALIDA
           MOVE 'S'    TO WS-CT-VALIDA
           MOVE 'S'    TO WS-VALOR-VALIDO
           MOVE 'S'    TO WS-DATA-VALIDA

           IF RJ-TIPO NOT = 'C' AND RJ-TIPO NOT = 'D'
               MOVE 'N' TO WS-TIPO-VALIDO
               MOVE 'TIPO INVALIDO' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

           IF RJ-AGENCIA NOT NUMERIC OR RJ-AGENCIA = ZEROS
               MOVE 'N' TO WS-AG-VALIDA
               MOVE 'AGENCIA INVALIDA' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

           IF RJ-NUM-CONTA NOT NUMERIC OR RJ-NUM-CONTA = ZEROS
               MOVE 'N' TO WS-CT-VALIDA
               MOVE 'CONTA INVALIDA' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

           IF RJ-VALOR NOT NUMERIC OR RJ-VALOR = ZEROS
               MOVE 'N' TO WS-VALOR-VALIDO
               MOVE 'VALOR INVALIDO' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

           IF RJ-DATA NOT NUMERIC OR RJ-DATA = ZEROS
               MOVE 'N' TO WS-DATA-VALIDA
               MOVE 'DATA INVALIDA' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

           PERFORM 2200-DESTINAR-REGISTRO.

       2200-DESTINAR-REGISTRO.
           IF WS-TIPO-VALIDO  = 'S'
           AND WS-AG-VALIDA   = 'S'
           AND WS-CT-VALIDA   = 'S'
           AND WS-VALOR-VALIDO = 'S'
           AND WS-DATA-VALIDA  = 'S'
               ADD 1 TO WS-RECUPERADOS
               MOVE REJEIT-IN-RAW TO LANCTO-OUT-REG
               WRITE LANCTO-OUT-REG
               PERFORM 5000-AUDITAR-RECUPERADO
           ELSE
               ADD 1 TO WS-MANTIDOS-REJ
               MOVE REJEIT-IN-RAW TO RO-DADOS-ORIG
               MOVE FUNCTION TRIM(WS-MOTIVO-ACUM TRAILING)
                   TO RO-MOTIVO
               WRITE REJEIT-OUT-REG
               PERFORM 5100-AUDITAR-PERMANENTE
           END-IF.

       2300-ACUMULAR-MOTIVO.
           IF WS-MOTIVO-ACUM = SPACES
               STRING FUNCTION TRIM(WS-MOTIVO-TEMP TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-ACUM
               END-STRING
           ELSE
               STRING FUNCTION TRIM(WS-MOTIVO-ACUM TRAILING)
                      ' | '
                      FUNCTION TRIM(WS-MOTIVO-TEMP TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-ACUM
               END-STRING
           END-IF.

       5000-AUDITAR-RECUPERADO.
           MOVE SPACES            TO AUDIT-REG-OUT
           MOVE 'EBREPR01'        TO AU-PROGRAMA
           MOVE WS-DATA-PROC      TO AU-DATA-EVENTO
           MOVE WS-HORA-PROC      TO AU-HORA-EVENTO
           MOVE 'OK'              TO AU-TIPO-EVENTO
           MOVE 'REGISTRO RECUPERADO' TO AU-MENSAGEM
           WRITE AUDIT-REG-OUT.

       5100-AUDITAR-PERMANENTE.
           MOVE SPACES            TO AUDIT-REG-OUT
           MOVE 'EBREPR01'        TO AU-PROGRAMA
           MOVE WS-DATA-PROC      TO AU-DATA-EVENTO
           MOVE WS-HORA-PROC      TO AU-HORA-EVENTO
           MOVE 'REJT'            TO AU-TIPO-EVENTO
           MOVE WS-MOTIVO-ACUM    TO AU-MENSAGEM
           WRITE AUDIT-REG-OUT.

       9000-ENCERRAR.
           DISPLAY '*** RESUMO EBREPR01 ***'
           DISPLAY 'REGISTROS LIDOS       : ' WS-LIDOS
           DISPLAY 'REGISTROS RECUPERADOS : ' WS-RECUPERADOS
           DISPLAY 'REJEITOS PERMANENTES  : ' WS-MANTIDOS-REJ

           CLOSE REJEIT-IN
           CLOSE LANCTO-OUT
           CLOSE REJEIT-OUT
           CLOSE AUDIT-OUT

           EVALUATE TRUE
               WHEN ERRO-IO-DETECTADO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-MANTIDOS-REJ > ZERO OR WS-LIDOS = ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
