       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBREPR01.
      *===============================================================*
      * PROGRAMA : EBREPR01                                           *
      * FUNCAO   : REPROCESSAR LANCAMENTOS REJEITADOS                 *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o arquivo de rejeitos gerado pela validacao (EBVALI01)   *
      * - Reaplica as regras de validacao nos registros corrigidos    *
      * - Grava registros agora validos no arquivo de lancamentos     *
      * - Grava registros ainda invalidos de volta no arquivo de      *
      *   rejeitos permanentes                                       *
      * - Gera auditoria de cada decisao (aceito / mantido rejeito)  *
      * - Exibe resumo com totais reprocessados                       *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Permitir correcao e reaproveitamento de lancamentos         *
      *   rejeitados sem resubmeter todo o arquivo do dia             *
      * - Simular o fluxo de reprocessamento sob demanda              *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Todos os rejeitos foram recuperados             *
      *   RC = 4  --> Ainda restam rejeitos ou entrada vazia          *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * REJEIT-IN = arquivo de rejeitos a reprocessar                 *
      *---------------------------------------------------------------*
           SELECT REJEIT-IN
               ASSIGN TO REJIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJIN.

      *---------------------------------------------------------------*
      * LANCTO-OUT = arquivo de lancamentos recuperados               *
      *---------------------------------------------------------------*
           SELECT LANCTO-OUT
               ASSIGN TO LCTOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-LCTOUT.

      *---------------------------------------------------------------*
      * REJEIT-OUT = arquivo de rejeitos permanentes                  *
      *---------------------------------------------------------------*
           SELECT REJEIT-OUT
               ASSIGN TO REJOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJOUT.

      *---------------------------------------------------------------*
      * AUDIT-OUT = arquivo de auditoria do reprocessamento           *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de rejeitos de entrada                                *
      * Layout: mesma estrutura de lancamento (120 bytes)             *
      *---------------------------------------------------------------*
       FD  REJEIT-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-IN-RAW              PIC X(120).

       01  REJEIT-IN-REG REDEFINES REJEIT-IN-RAW.
           05 RJ-AGENCIA              PIC X(4).
           05 RJ-CONTA                PIC X(8).
           05 RJ-DATA                 PIC X(8).
           05 RJ-TIPO                 PIC X(1).
           05 RJ-VALOR                PIC X(13).
           05 RJ-HISTORICO            PIC X(30).
           05 RJ-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Arquivo de lancamentos recuperados                            *
      *---------------------------------------------------------------*
       FD  LANCTO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  LANCTO-OUT-RAW             PIC X(120).

      *---------------------------------------------------------------*
      * Arquivo de rejeitos permanentes                               *
      *---------------------------------------------------------------*
       FD  REJEIT-OUT
           RECORD CONTAINS 150 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-OUT-REG             PIC X(150).

      *---------------------------------------------------------------*
      * Arquivo de auditoria                                          *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status dos arquivos                                      *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-REJIN             PIC XX.
              88 FS-REJIN-OK          VALUE '00'.
              88 FS-REJIN-EOF         VALUE '10'.
           05 WS-FS-LCTOUT            PIC XX.
              88 FS-LCTOUT-OK         VALUE '00'.
           05 WS-FS-REJOUT            PIC XX.
              88 FS-REJOUT-OK         VALUE '00'.
           05 WS-FS-AUDIT             PIC XX.
              88 FS-AUDIT-OK          VALUE '00'.

      *---------------------------------------------------------------*
      * Controle de processamento                                     *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-REJIN            PIC X VALUE 'N'.
              88 EOF-REJIN            VALUE 'S'.
              88 NAO-EOF-REJIN        VALUE 'N'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ARQUIVOS.
           05 WS-REJIN-ABERTO         PIC X VALUE 'N'.
              88 REJIN-ABERTO         VALUE 'S'.
           05 WS-LCTOUT-ABERTO        PIC X VALUE 'N'.
              88 LCTOUT-ABERTO        VALUE 'S'.
           05 WS-REJOUT-ABERTO        PIC X VALUE 'N'.
              88 REJOUT-ABERTO        VALUE 'S'.
           05 WS-AUDIT-ABERTO         PIC X VALUE 'N'.
              88 AUDIT-ABERTO         VALUE 'S'.

      *---------------------------------------------------------------*
      * Flag de validacao do registro atual                           *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-REG-VALIDO           PIC X VALUE 'S'.
              88 REGISTRO-VALIDO      VALUE 'S'.
              88 REGISTRO-INVALIDO    VALUE 'N'.

      *---------------------------------------------------------------*
      * Acumulador de motivos de rejeicao                             *
      *---------------------------------------------------------------*
       01  WS-MOTIVOS.
           05 WS-MOTIVO-CONCAT        PIC X(100) VALUE SPACES.
           05 WS-MOTIVO-AUX           PIC X(100) VALUE SPACES.
           05 WS-NOVO-MOTIVO          PIC X(25)  VALUE SPACES.

      *---------------------------------------------------------------*
      * Campos numericos de trabalho (usados apos IS NUMERIC)         *
      *---------------------------------------------------------------*
       01  WS-CAMPOS-NUMERICOS.
           05 WS-AGENCIA-NUM          PIC 9(4)    VALUE ZERO.
           05 WS-CONTA-NUM            PIC 9(8)    VALUE ZERO.
           05 WS-DATA-NUM             PIC 9(8)    VALUE ZERO.
           05 WS-VALOR-NUM            PIC 9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Contadores                                                    *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(9) VALUE ZERO.
           05 WS-RECUPERADOS          PIC 9(9) VALUE ZERO.
           05 WS-MANTIDOS-REJ         PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Campos de edicao para rodape                                  *
      *---------------------------------------------------------------*
       01  WS-EDIT-LIDOS              PIC ZZZ.ZZZ.ZZ9.
       01  WS-EDIT-RECUP              PIC ZZZ.ZZZ.ZZ9.
       01  WS-EDIT-MANT               PIC ZZZ.ZZZ.ZZ9.

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-PROCESSAR-REJEITOS
           END-IF
           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-EXIBIR-RESUMO-E-DEFINIR-RC
           GOBACK.

      *---------------------------------------------------------------*
      * Abre todos os arquivos                                        *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  REJEIT-IN
           IF FS-REJIN-OK
               SET REJIN-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN REJEIT-IN - STATUS: '
                       WS-FS-REJIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT LANCTO-OUT
               IF FS-LCTOUT-OK
                   SET LCTOUT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN LANCTO-OUT - STATUS: '
                           WS-FS-LCTOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT REJEIT-OUT
               IF FS-REJOUT-OK
                   SET REJOUT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN REJEIT-OUT - STATUS: '
                           WS-FS-REJOUT
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
      * Loop principal de leitura dos rejeitos                        *
      *---------------------------------------------------------------*
       2000-PROCESSAR-REJEITOS.
           PERFORM UNTIL EOF-REJIN OR OCORREU-ERRO-IO
               READ REJEIT-IN
                   AT END
                       SET EOF-REJIN TO TRUE
                   NOT AT END
                       IF FS-REJIN-OK
                           ADD 1 TO WS-LIDOS
                           PERFORM 2100-REVALIDAR-REGISTRO
                           PERFORM 2200-DESTINAR-REGISTRO
                       ELSE
                           DISPLAY '*** ERRO READ REJEIT-IN STATUS: '
                                   WS-FS-REJIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Reaplica as mesmas regras de validacao do EBVALI01             *
      *---------------------------------------------------------------*
       2100-REVALIDAR-REGISTRO.
           SET REGISTRO-VALIDO TO TRUE
           MOVE SPACES TO WS-MOTIVO-CONCAT
                          WS-MOTIVO-AUX

      *    Regra 1: tipo deve ser C ou D
           IF RJ-TIPO NOT = 'C'
              AND RJ-TIPO NOT = 'D'
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'TIPO INVALIDO' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 2: agencia numerica e maior que zero
           IF RJ-AGENCIA IS NUMERIC
               MOVE RJ-AGENCIA TO WS-AGENCIA-NUM
               IF WS-AGENCIA-NUM = ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'AGENCIA INVALIDA' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'AGENCIA INVALIDA' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 3: conta numerica e maior que zero
           IF RJ-CONTA IS NUMERIC
               MOVE RJ-CONTA TO WS-CONTA-NUM
               IF WS-CONTA-NUM = ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'CONTA INVALIDA' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'CONTA INVALIDA' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 4: valor numerico e maior que zero
           IF RJ-VALOR IS NUMERIC
               MOVE RJ-VALOR TO WS-VALOR-NUM
               IF WS-VALOR-NUM <= ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'VALOR INVALIDO' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'VALOR INVALIDO' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 5: data numerica e diferente de zero
           IF RJ-DATA IS NUMERIC
               MOVE RJ-DATA TO WS-DATA-NUM
               IF WS-DATA-NUM = ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'DATA INVALIDA' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'DATA INVALIDA' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF.

      *---------------------------------------------------------------*
      * Acumula motivos de rejeicao separados por ' | '               *
      *---------------------------------------------------------------*
       2300-ACUMULAR-MOTIVO.
           MOVE SPACES TO WS-MOTIVO-AUX

           IF FUNCTION TRIM(WS-MOTIVO-CONCAT TRAILING) = SPACES
               STRING FUNCTION TRIM(WS-NOVO-MOTIVO TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-AUX
                      ON OVERFLOW
                          DISPLAY '*** OVERFLOW ACUMULANDO MOTIVO'
               END-STRING
           ELSE
               STRING FUNCTION TRIM(WS-MOTIVO-CONCAT TRAILING)
                      ' | '
                      FUNCTION TRIM(WS-NOVO-MOTIVO TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-AUX
                      ON OVERFLOW
                          DISPLAY '*** OVERFLOW ACUMULANDO MOTIVO'
               END-STRING
           END-IF

           MOVE WS-MOTIVO-AUX TO WS-MOTIVO-CONCAT.

      *---------------------------------------------------------------*
      * Direciona registro para recuperados ou rejeitos permanentes   *
      *---------------------------------------------------------------*
       2200-DESTINAR-REGISTRO.
           IF REGISTRO-VALIDO
               MOVE REJEIT-IN-RAW TO LANCTO-OUT-RAW
               WRITE LANCTO-OUT-RAW
               IF NOT FS-LCTOUT-OK
                   DISPLAY '*** ERRO WRITE LANCTO-OUT - STATUS: '
                           WS-FS-LCTOUT
                   SET OCORREU-ERRO-IO TO TRUE
               ELSE
                   ADD 1 TO WS-RECUPERADOS
                   MOVE SPACES TO AUDIT-REG
                   STRING 'REPR RECUPERADO - AG '
                          RJ-AGENCIA
                          ' CTA '
                          RJ-CONTA
                          ' TIPO '
                          RJ-TIPO
                          ' DATA '
                          RJ-DATA
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   PERFORM 7000-GRAVAR-AUDITORIA
               END-IF
           ELSE
               MOVE SPACES TO REJEIT-OUT-REG
               STRING 'REPR MANTIDO | '
                      FUNCTION TRIM(WS-MOTIVO-CONCAT TRAILING)
                      ' | AG '
                      RJ-AGENCIA
                      ' CTA '
                      RJ-CONTA
                      ' DATA '
                      RJ-DATA
                      ' TIPO '
                      RJ-TIPO
                      DELIMITED BY SIZE
                      INTO REJEIT-OUT-REG
                      ON OVERFLOW
                          DISPLAY '*** OVERFLOW REJEIT AG:'
                                  RJ-AGENCIA ' CTA:' RJ-CONTA
               END-STRING

               WRITE REJEIT-OUT-REG
               IF NOT FS-REJOUT-OK
                   DISPLAY '*** ERRO WRITE REJEIT-OUT - STATUS: '
                           WS-FS-REJOUT
                   SET OCORREU-ERRO-IO TO TRUE
               ELSE
                   ADD 1 TO WS-MANTIDOS-REJ
                   MOVE SPACES TO AUDIT-REG
                   STRING 'REPR MANTIDO REJ - AG '
                          RJ-AGENCIA
                          ' CTA '
                          RJ-CONTA
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   PERFORM 7000-GRAVAR-AUDITORIA
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Grava registro de auditoria                                   *
      *---------------------------------------------------------------*
       7000-GRAVAR-AUDITORIA.
           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** ERRO WRITE AUDIT - STATUS: '
                       WS-FS-AUDIT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Fecha todos os arquivos                                       *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF REJIN-ABERTO
               CLOSE REJEIT-IN
               IF NOT FS-REJIN-OK
                   DISPLAY '*** ERRO CLOSE REJEIT-IN - STATUS: '
                           WS-FS-REJIN
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF LCTOUT-ABERTO
               CLOSE LANCTO-OUT
               IF NOT FS-LCTOUT-OK
                   DISPLAY '*** ERRO CLOSE LANCTO-OUT - STATUS: '
                           WS-FS-LCTOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF REJOUT-ABERTO
               CLOSE REJEIT-OUT
               IF NOT FS-REJOUT-OK
                   DISPLAY '*** ERRO CLOSE REJEIT-OUT - STATUS: '
                           WS-FS-REJOUT
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
       9100-EXIBIR-RESUMO-E-DEFINIR-RC.
           DISPLAY '*** RESUMO REPROCESSAMENTO ***'
           DISPLAY 'REJEITOS LIDOS       : ' WS-LIDOS
           DISPLAY 'REGISTROS RECUPERADOS: ' WS-RECUPERADOS
           DISPLAY 'REJEITOS MANTIDOS    : ' WS-MANTIDOS-REJ

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-LIDOS = ZERO
                   DISPLAY '*** ATENCAO: ARQUIVO DE REJEITOS VAZIO'
                   MOVE 4 TO RETURN-CODE
               WHEN WS-MANTIDOS-REJ > ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
