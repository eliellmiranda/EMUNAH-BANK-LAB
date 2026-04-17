       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCONC01.
      *===============================================================*
      * PROGRAMA : EBCONC01                                           *
      * FUNCAO   : VALIDAR / CONCILIAR MOVIMENTOS                     *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le um arquivo sequencial de movimentos/lancamentos          *
      * - Valida o tipo de movimento (C = Credito, D = Debito)        *
      * - Gera saida de conciliacao com registros aceitos             *
      * - Gera mensagens de rejeicao para registros invalidos         *
      * - Exibe resumo com totais lidos, conciliados e rejeitados     *
      * - Grava linha de totalizacao no arquivo de saida              *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Processamento OK, sem rejeitos                  *
      *   RC = 4  --> Processamento OK com rejeitos ou arquivo vazio  *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      *---------------------------------------------------------------*
      * MOVTO-IN = arquivo de entrada com os movimentos a conciliar   *
      *---------------------------------------------------------------*
           SELECT MOVTO-IN
               ASSIGN TO MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * CONCIL-OUT = arquivo de saida com o resultado da conciliacao  *
      *---------------------------------------------------------------*
           SELECT CONCIL-OUT
               ASSIGN TO CONCOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-CONCOUT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de movimentos                               *
      * Total: 4 + 8 + 8 + 1 + 13 + 30 + 10 + 46 = 120 bytes         *
      *---------------------------------------------------------------*
       FD  MOVTO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  MOVTO-IN-REG.
           05 MV-AGENCIA              PIC 9(4).
           05 MV-CONTA                PIC 9(8).
           05 MV-DATA                 PIC 9(8).
           05 MV-TIPO                 PIC X(1).
           05 MV-VALOR                PIC 9(11)V99.
           05 MV-HISTORICO            PIC X(30).
           05 MV-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Arquivo de saida da conciliacao                               *
      *---------------------------------------------------------------*
       FD  CONCIL-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  CONCIL-REG                 PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status para controle de operacoes nos arquivos           *
      * '00' = sucesso   '10' = fim de arquivo                        *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-MOVTIN            PIC XX VALUE SPACES.
              88 FS-MOVTIN-OK         VALUE '00'.
              88 FS-MOVTIN-EOF        VALUE '10'.
           05 WS-FS-CONCOUT           PIC XX VALUE SPACES.
              88 FS-CONCOUT-OK        VALUE '00'.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-MOVTO            PIC X VALUE 'N'.
              88 EOF-MOVTO            VALUE 'S'.
              88 NAO-EOF-MOVTO        VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de erro de I/O                                       *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ARQUIVOS.
           05 WS-MOVTIN-ABERTO        PIC X VALUE 'N'.
              88 MOVTIN-ABERTO        VALUE 'S'.
           05 WS-CONCOUT-ABERTO       PIC X VALUE 'N'.
              88 CONCOUT-ABERTO       VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores para resumo final                                  *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-TOTAL-LIDOS          PIC 9(9) VALUE ZERO.
           05 WS-TOTAL-CONCILIADOS    PIC 9(9) VALUE ZERO.
           05 WS-TOTAL-REJEITADOS     PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Campo de edicao para formatar valor na saida                  *
      * MV-VALOR = 11 inteiros + 2 decimais                           *
      *---------------------------------------------------------------*
       01  WS-VALOR-EDIT              PIC ZZ.ZZZ.ZZZ.ZZ9,99.

      *---------------------------------------------------------------*
      * Campos de edicao dos totais para rodape do arquivo            *
      *---------------------------------------------------------------*
       01  WS-EDIT-LIDOS              PIC ZZZ.ZZZ.ZZ9.
       01  WS-EDIT-CONCIL             PIC ZZZ.ZZZ.ZZ9.
       01  WS-EDIT-REJEIT             PIC ZZZ.ZZZ.ZZ9.

       PROCEDURE DIVISION.

      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS

           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-PROCESSAR-MOVIMENTOS
           END-IF

           IF NAO-OCORREU-ERRO-IO
               PERFORM 3000-GRAVAR-TOTAIS
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos de entrada e saida                           *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT MOVTO-IN

           IF FS-MOVTIN-OK
               SET MOVTIN-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN MOVTO-IN - STATUS: '
                       WS-FS-MOVTIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT CONCIL-OUT

               IF FS-CONCOUT-OK
                   SET CONCOUT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN CONCIL-OUT - STATUS: '
                           WS-FS-CONCOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Loop principal de leitura do arquivo de movimentos            *
      *---------------------------------------------------------------*
       2000-PROCESSAR-MOVIMENTOS.
           PERFORM UNTIL EOF-MOVTO OR OCORREU-ERRO-IO

               READ MOVTO-IN
                   AT END
                       SET EOF-MOVTO TO TRUE
                   NOT AT END
                       IF FS-MOVTIN-OK
                           ADD 1 TO WS-TOTAL-LIDOS
                           PERFORM 2100-VALIDAR-E-CONCILIAR
                       ELSE
                           DISPLAY '*** ERRO READ MOVTO-IN - STATUS: '
                                   WS-FS-MOVTIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ

           END-PERFORM.

      *---------------------------------------------------------------*
      * Valida o tipo do movimento e monta a linha de saida           *
      *---------------------------------------------------------------*
       2100-VALIDAR-E-CONCILIAR.
           MOVE SPACES TO CONCIL-REG

           IF MV-TIPO = 'C' OR MV-TIPO = 'D'
               ADD 1 TO WS-TOTAL-CONCILIADOS
               MOVE MV-VALOR TO WS-VALOR-EDIT

               STRING 'CONCILIADO - AG '
                      MV-AGENCIA
                      ' CTA '
                      MV-CONTA
                      ' DATA '
                      MV-DATA
                      ' TIPO '
                      MV-TIPO
                      ' VALOR '
                      WS-VALOR-EDIT
                      DELIMITED BY SIZE
                      INTO CONCIL-REG
               END-STRING
           ELSE
               ADD 1 TO WS-TOTAL-REJEITADOS

               STRING 'REJEITADO - TIPO INVALIDO - AG '
                      MV-AGENCIA
                      ' CTA '
                      MV-CONTA
                      ' DATA '
                      MV-DATA
                      DELIMITED BY SIZE
                      INTO CONCIL-REG
               END-STRING
           END-IF

           PERFORM 2200-GRAVAR-SAIDA.

      *---------------------------------------------------------------*
      * Grava registro no arquivo de saida e valida FILE STATUS       *
      *---------------------------------------------------------------*
       2200-GRAVAR-SAIDA.
           WRITE CONCIL-REG

           IF NOT FS-CONCOUT-OK
               DISPLAY '*** ERRO WRITE CONCIL-OUT - STATUS: '
                       WS-FS-CONCOUT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Grava linha de totalizacao no arquivo de saida                *
      *---------------------------------------------------------------*
       3000-GRAVAR-TOTAIS.
           MOVE WS-TOTAL-LIDOS       TO WS-EDIT-LIDOS
           MOVE WS-TOTAL-CONCILIADOS TO WS-EDIT-CONCIL
           MOVE WS-TOTAL-REJEITADOS  TO WS-EDIT-REJEIT
           MOVE SPACES               TO CONCIL-REG

           STRING '*** TOTAIS - LIDOS: '
                  WS-EDIT-LIDOS
                  ' CONCIL: '
                  WS-EDIT-CONCIL
                  ' REJEIT: '
                  WS-EDIT-REJEIT
                  DELIMITED BY SIZE
                  INTO CONCIL-REG
           END-STRING

           PERFORM 2200-GRAVAR-SAIDA.

      *---------------------------------------------------------------*
      * Fecha arquivos e valida FILE STATUS                           *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF MOVTIN-ABERTO
               CLOSE MOVTO-IN
               IF NOT FS-MOVTIN-OK
                   DISPLAY '*** ERRO CLOSE MOVTO-IN - STATUS: '
                           WS-FS-MOVTIN
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF CONCOUT-ABERTO
               CLOSE CONCIL-OUT
               IF NOT FS-CONCOUT-OK
                   DISPLAY '*** ERRO CLOSE CONCIL-OUT - STATUS: '
                           WS-FS-CONCOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo final e define RETURN-CODE                       *
      *---------------------------------------------------------------*
       9100-DEFINIR-RETURN-CODE.
           DISPLAY '*** RESUMO CONCILIACAO ***'
           DISPLAY 'MOVIMENTOS LIDOS       : ' WS-TOTAL-LIDOS
           DISPLAY 'MOVIMENTOS CONCILIADOS : ' WS-TOTAL-CONCILIADOS
           DISPLAY 'MOVIMENTOS REJEITADOS  : ' WS-TOTAL-REJEITADOS

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-TOTAL-LIDOS = ZERO
                   DISPLAY '*** ATENCAO: ARQUIVO DE ENTRADA VAZIO'
                   MOVE 4 TO RETURN-CODE
               WHEN WS-TOTAL-REJEITADOS > ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
