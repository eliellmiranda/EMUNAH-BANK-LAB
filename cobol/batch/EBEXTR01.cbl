       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBEXTR01.
      *===============================================================*
      * PROGRAMA : EBEXTR01                                           *
      * FUNCAO   : GERAR EXTRATO DE MOVIMENTOS DO DIA                 *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le os lancamentos validos/postados (LANCTO.ESDS via MOVTIN) *
      * - Formata cada movimento como linha de extrato                *
      * - Grava cabecalho, detalhe e rodape em EXTROUT                *
      * - EXTROUT aponta para ARQ.EXTRATO.GDG(+1) via JCL             *
      *   (nova geracao GDG a cada execucao)                          *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Extrato gerado com sucesso                      *
      *   RC = 4  --> Arquivo de entrada vazio                        *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * MOVTIN = lancamentos validos postados (LANCTO.ESDS)           *
      *---------------------------------------------------------------*
           SELECT MOVTO-IN
               ASSIGN TO MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * EXTROUT = saida do extrato (aponta para GDG(+1) no JCL)       *
      *---------------------------------------------------------------*
           SELECT EXTRATO-OUT
               ASSIGN TO EXTROUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-EXTROUT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Lancamentos validos (120 bytes)                               *
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
      * Extrato de saida (132 colunas)                                *
      *---------------------------------------------------------------*
       FD  EXTRATO-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  EXTRATO-REG                PIC X(132).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status                                                   *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-MOVTIN            PIC XX VALUE SPACES.
              88 FS-MOVTIN-OK         VALUE '00'.
              88 FS-MOVTIN-EOF        VALUE '10'.
           05 WS-FS-EXTROUT           PIC XX VALUE SPACES.
              88 FS-EXTROUT-OK        VALUE '00'.

      *---------------------------------------------------------------*
      * Controles                                                     *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-MOVTO            PIC X VALUE 'N'.
              88 EOF-MOVTO            VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ARQUIVOS.
           05 WS-MOVTIN-ABERTO        PIC X VALUE 'N'.
              88 MOVTIN-ABERTO        VALUE 'S'.
           05 WS-EXTROUT-ABERTO       PIC X VALUE 'N'.
              88 EXTROUT-ABERTO       VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores                                                    *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-TOTAL-LIDOS          PIC 9(9) VALUE ZERO.
           05 WS-TOTAL-CREDITOS       PIC 9(9) VALUE ZERO.
           05 WS-TOTAL-DEBITOS        PIC 9(9) VALUE ZERO.
           05 WS-TOTAL-INVALIDOS      PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Area de formatacao do movimento                               *
      *---------------------------------------------------------------*
       01  WS-AREA-TRABALHO.
           05 WS-DATA-FMT.
              10 WS-DATA-ANO          PIC X(4).
              10 FILLER               PIC X VALUE '-'.
              10 WS-DATA-MES          PIC X(2).
              10 FILLER               PIC X VALUE '-'.
              10 WS-DATA-DIA          PIC X(2).
           05 WS-VALOR-EDIT           PIC ZZZ.ZZZ.ZZ9,99.
           05 WS-TIPO-DESC            PIC X(7).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-GERAR-EXTRATO
           END-IF
           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos e verifica FILE STATUS                       *
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
               OPEN OUTPUT EXTRATO-OUT
               IF FS-EXTROUT-OK
                   SET EXTROUT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN EXTRATO-OUT - STATUS: '
                           WS-FS-EXTROUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Gera o extrato completo                                       *
      *---------------------------------------------------------------*
       2000-GERAR-EXTRATO.
           PERFORM 2100-GERAR-CABECALHO
           PERFORM UNTIL EOF-MOVTO OR OCORREU-ERRO-IO
               READ MOVTO-IN
                   AT END
                       SET EOF-MOVTO TO TRUE
                   NOT AT END
                       IF FS-MOVTIN-OK
                           ADD 1 TO WS-TOTAL-LIDOS
                           PERFORM 2200-TRATAR-MOVIMENTO
                       ELSE
                           DISPLAY '*** ERRO READ MOVTO-IN - STATUS: '
                                   WS-FS-MOVTIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM
           IF NAO-OCORREU-ERRO-IO
               PERFORM 2300-GERAR-RODAPE
           END-IF.

      *---------------------------------------------------------------*
      * Grava cabecalho do extrato                                    *
      *---------------------------------------------------------------*
       2100-GERAR-CABECALHO.
           MOVE ALL '-' TO EXTRATO-REG
           PERFORM 2900-ESCREVER-EXTRATO

           MOVE SPACES TO EXTRATO-REG
           MOVE 'EXTRATO DE MOVIMENTOS - EMUNAH BANK LAB'
               TO EXTRATO-REG
           PERFORM 2900-ESCREVER-EXTRATO

           MOVE SPACES TO EXTRATO-REG
           MOVE 'DATA       AG   CONTA      TIPO     '
               TO EXTRATO-REG(1:37)
           MOVE 'VALOR            HISTORICO'
               TO EXTRATO-REG(38:26)
           PERFORM 2900-ESCREVER-EXTRATO

           MOVE ALL '-' TO EXTRATO-REG
           PERFORM 2900-ESCREVER-EXTRATO.

      *---------------------------------------------------------------*
      * Trata cada movimento de acordo com o tipo                     *
      *---------------------------------------------------------------*
       2200-TRATAR-MOVIMENTO.
           EVALUATE MV-TIPO
               WHEN 'C'
                   MOVE 'CREDITO' TO WS-TIPO-DESC
                   ADD 1 TO WS-TOTAL-CREDITOS
                   PERFORM 2210-ESCREVER-LINHA
               WHEN 'D'
                   MOVE 'DEBITO ' TO WS-TIPO-DESC
                   ADD 1 TO WS-TOTAL-DEBITOS
                   PERFORM 2210-ESCREVER-LINHA
               WHEN OTHER
                   ADD 1 TO WS-TOTAL-INVALIDOS
                   DISPLAY '*** TIPO INVALIDO IGNORADO: '
                           MV-TIPO
                           ' AG: ' MV-AGENCIA
                           ' CTA: ' MV-CONTA
           END-EVALUATE.

      *---------------------------------------------------------------*
      * Formata e grava a linha de detalhe do movimento               *
      *---------------------------------------------------------------*
       2210-ESCREVER-LINHA.
           MOVE MV-DATA(1:4) TO WS-DATA-ANO
           MOVE MV-DATA(5:2) TO WS-DATA-MES
           MOVE MV-DATA(7:2) TO WS-DATA-DIA
           MOVE MV-VALOR     TO WS-VALOR-EDIT

           MOVE SPACES TO EXTRATO-REG
           STRING WS-DATA-FMT
                  '  '
                  MV-AGENCIA
                  '  '
                  MV-CONTA
                  '  '
                  WS-TIPO-DESC
                  '  '
                  WS-VALOR-EDIT
                  '  '
                  MV-HISTORICO
                  DELIMITED BY SIZE INTO EXTRATO-REG
           END-STRING
           PERFORM 2900-ESCREVER-EXTRATO.

      *---------------------------------------------------------------*
      * Grava rodape com totais do extrato                            *
      *---------------------------------------------------------------*
       2300-GERAR-RODAPE.
           MOVE ALL '-' TO EXTRATO-REG
           PERFORM 2900-ESCREVER-EXTRATO

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL LIDOS     : '
                  WS-TOTAL-LIDOS
                  DELIMITED BY SIZE INTO EXTRATO-REG
           END-STRING
           PERFORM 2900-ESCREVER-EXTRATO

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL CREDITOS  : '
                  WS-TOTAL-CREDITOS
                  DELIMITED BY SIZE INTO EXTRATO-REG
           END-STRING
           PERFORM 2900-ESCREVER-EXTRATO

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL DEBITOS   : '
                  WS-TOTAL-DEBITOS
                  DELIMITED BY SIZE INTO EXTRATO-REG
           END-STRING
           PERFORM 2900-ESCREVER-EXTRATO

           IF WS-TOTAL-INVALIDOS > ZERO
               MOVE SPACES TO EXTRATO-REG
               STRING 'TOTAL INVALIDOS : '
                      WS-TOTAL-INVALIDOS
                      DELIMITED BY SIZE INTO EXTRATO-REG
               END-STRING
               PERFORM 2900-ESCREVER-EXTRATO
           END-IF

           MOVE ALL '-' TO EXTRATO-REG
           PERFORM 2900-ESCREVER-EXTRATO.

      *---------------------------------------------------------------*
      * Grava linha no extrato e verifica FILE STATUS                 *
      *---------------------------------------------------------------*
       2900-ESCREVER-EXTRATO.
           WRITE EXTRATO-REG
           IF NOT FS-EXTROUT-OK
               DISPLAY '*** ERRO WRITE EXTRATO-OUT - STATUS: '
                       WS-FS-EXTROUT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Fecha arquivos com verificacao de FILE STATUS                 *
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

           IF EXTROUT-ABERTO
               CLOSE EXTRATO-OUT
               IF NOT FS-EXTROUT-OK
                   DISPLAY '*** ERRO CLOSE EXTRATO-OUT - STATUS: '
                           WS-FS-EXTROUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo e define RETURN-CODE                             *
      *---------------------------------------------------------------*
       9100-DEFINIR-RETURN-CODE.
           DISPLAY '*** RESUMO EXTRATO ***'
           DISPLAY 'MOVIMENTOS LIDOS    : ' WS-TOTAL-LIDOS
           DISPLAY 'CREDITOS            : ' WS-TOTAL-CREDITOS
           DISPLAY 'DEBITOS             : ' WS-TOTAL-DEBITOS
           DISPLAY 'INVALIDOS IGNORADOS : ' WS-TOTAL-INVALIDOS

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-TOTAL-LIDOS = ZERO
                   DISPLAY '*** ATENCAO: LANCTO.ESDS VAZIO'
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.