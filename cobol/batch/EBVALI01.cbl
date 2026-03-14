       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBVALI01.
      *===============================================================*
      * PROGRAMA: EBVALI01                                            *
      * FUNCAO : VALIDAR LANCAMENTOS DE ENTRADA                       *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le um arquivo sequencial de lancamentos                     *
      * - Valida campos basicos do movimento                          *
      *   . tipo do movimento                                         *
      *   . agencia                                                   *
      *   . conta                                                     *
      *   . valor                                                     *
      *   . data                                                      *
      * - Se o registro estiver valido, grava no arquivo de validos   *
      * - Se estiver invalido, grava no arquivo de rejeitados         *
      * - Ao final, exibe um resumo com totais                        *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular a etapa de validacao antes da postagem              *
      * - Separar movimentos bons de movimentos com erro              *
      * - Produzir massa limpa para o proximo job batch               *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * ENTRADA-IN = arquivo bruto de lancamentos                     *
      *---------------------------------------------------------------*
           SELECT ENTRADA-IN
               ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ENTRADA.

      *---------------------------------------------------------------*
      * VALIDOS-OUT = arquivo com movimentos aprovados                *
      *---------------------------------------------------------------*
           SELECT VALIDOS-OUT
               ASSIGN TO VALIDOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-VALIDOS.

      *---------------------------------------------------------------*
      * REJEIT-OUT = arquivo com movimentos rejeitados                *
      *---------------------------------------------------------------*
           SELECT REJEIT-OUT
               ASSIGN TO REJEITOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJEITOS.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de entrada                                  *
      *---------------------------------------------------------------*
       FD  ENTRADA-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ENTRADA-REG.
           05 EN-AGENCIA              PIC 9(4).
           05 EN-CONTA                PIC 9(8).
           05 EN-DATA                 PIC 9(8).
           05 EN-TIPO                 PIC X(1).
           05 EN-VALOR                PIC 9(11)V99.
           05 EN-HISTORICO            PIC X(30).
           05 EN-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Arquivo de saida de validos                                   *
      * Mantem o mesmo layout da entrada                              *
      *---------------------------------------------------------------*
       FD  VALIDOS-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  VALIDOS-REG.
           05 VL-AGENCIA              PIC 9(4).
           05 VL-CONTA                PIC 9(8).
           05 VL-DATA                 PIC 9(8).
           05 VL-TIPO                 PIC X(1).
           05 VL-VALOR                PIC 9(11)V99.
           05 VL-HISTORICO            PIC X(30).
           05 VL-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Arquivo de rejeitados com mensagem de erro                    *
      *---------------------------------------------------------------*
       FD  REJEIT-OUT
           RECORD CONTAINS 150 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-REG                 PIC X(150).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status dos arquivos                                      *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-ENTRADA           PIC XX.
           05 WS-FS-VALIDOS           PIC XX.
           05 WS-FS-REJEITOS          PIC XX.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-ENTRADA          PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores de processamento                                   *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(5) VALUE ZERO.
           05 WS-VALIDOS              PIC 9(5) VALUE ZERO.
           05 WS-REJEITADOS           PIC 9(5) VALUE ZERO.

      *---------------------------------------------------------------*
      * Flag de validacao do registro atual                           *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-REG-VALIDO           PIC X VALUE 'S'.

      *---------------------------------------------------------------*
      * Mensagem de rejeicao do registro atual                        *
      *---------------------------------------------------------------*
       01  WS-MOTIVO-REJEICAO         PIC X(80).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-PROCESSAR-ENTRADA
           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos                                              *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  ENTRADA-IN
           OPEN OUTPUT VALIDOS-OUT
           OPEN OUTPUT REJEIT-OUT.

      *---------------------------------------------------------------*
      * Loop principal de leitura                                     *
      *---------------------------------------------------------------*
       2000-PROCESSAR-ENTRADA.
           PERFORM UNTIL WS-EOF-ENTRADA = 'S'
               READ ENTRADA-IN
                   AT END
                       MOVE 'S' TO WS-EOF-ENTRADA
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       PERFORM 2100-VALIDAR-REGISTRO
                       PERFORM 2200-DESTINAR-REGISTRO
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Valida o registro lido                                        *
      * Regras basicas:                                               *
      * - tipo deve ser C ou D                                        *
      * - agencia deve ser maior que zero                             *
      * - conta deve ser maior que zero                               *
      * - valor deve ser maior que zero                               *
      * - data deve ser numerica diferente de zero                    *
      *---------------------------------------------------------------*
       2100-VALIDAR-REGISTRO.
           MOVE 'S' TO WS-REG-VALIDO
           MOVE SPACES TO WS-MOTIVO-REJEICAO

           IF EN-TIPO NOT = 'C'
              AND EN-TIPO NOT = 'D'
               MOVE 'N' TO WS-REG-VALIDO
               MOVE 'TIPO INVALIDO' TO WS-MOTIVO-REJEICAO
           END-IF

           IF WS-REG-VALIDO = 'S'
              AND EN-AGENCIA = ZERO
               MOVE 'N' TO WS-REG-VALIDO
               MOVE 'AGENCIA INVALIDA' TO WS-MOTIVO-REJEICAO
           END-IF

           IF WS-REG-VALIDO = 'S'
              AND EN-CONTA = ZERO
               MOVE 'N' TO WS-REG-VALIDO
               MOVE 'CONTA INVALIDA' TO WS-MOTIVO-REJEICAO
           END-IF

           IF WS-REG-VALIDO = 'S'
              AND EN-VALOR <= ZERO
               MOVE 'N' TO WS-REG-VALIDO
               MOVE 'VALOR INVALIDO' TO WS-MOTIVO-REJEICAO
           END-IF

           IF WS-REG-VALIDO = 'S'
              AND EN-DATA = ZERO
               MOVE 'N' TO WS-REG-VALIDO
               MOVE 'DATA INVALIDA' TO WS-MOTIVO-REJEICAO
           END-IF.

      *---------------------------------------------------------------*
      * Direciona o registro para validos ou rejeitados               *
      *---------------------------------------------------------------*
       2200-DESTINAR-REGISTRO.
           IF WS-REG-VALIDO = 'S'
               MOVE ENTRADA-REG TO VALIDOS-REG
               WRITE VALIDOS-REG
               ADD 1 TO WS-VALIDOS
           ELSE
               MOVE SPACES TO REJEIT-REG
               STRING 'REJEITADO - '
                      WS-MOTIVO-REJEICAO
                      ' - AG '
                      EN-AGENCIA
                      ' CTA '
                      EN-CONTA
                      ' DATA '
                      EN-DATA
                      DELIMITED BY SIZE
                      INTO REJEIT-REG
               END-STRING
               WRITE REJEIT-REG
               ADD 1 TO WS-REJEITADOS
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo e fecha arquivos                                 *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO VALIDACAO ***'
           DISPLAY 'REGISTROS LIDOS      : ' WS-LIDOS
           DISPLAY 'REGISTROS VALIDOS    : ' WS-VALIDOS
           DISPLAY 'REGISTROS REJEITADOS : ' WS-REJEITADOS

           CLOSE ENTRADA-IN
           CLOSE VALIDOS-OUT
           CLOSE REJEIT-OUT.
