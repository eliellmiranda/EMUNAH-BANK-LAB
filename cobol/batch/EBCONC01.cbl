       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCONC01.
      *===============================================================*
      * PROGRAMA: EBCONC01                                            *
      * FUNCAO : CONCILIAR MOVIMENTOS                                 *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le um arquivo sequencial de movimentos/lancamentos          *
      * - Valida o tipo de movimento                                  *
      * - Gera uma saida de conciliacao com registros aceitos         *
      * - Gera mensagens de rejeicao para registros invalidos         *
      * - Exibe um resumo com totais lidos, conciliados e rejeitados  *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular a etapa batch de conciliacao                        *
      * - Conferir se os lancamentos estao aptos para fechamento      *
      * - Produzir trilha de conferencia operacional                  *
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
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * CONCIL-OUT = arquivo de saida com o resultado da conciliacao  *
      *---------------------------------------------------------------*
           SELECT CONCIL-OUT
               ASSIGN TO CONCOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONCOUT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de movimentos                               *
      * Cada registro representa um lancamento                        *
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
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-MOVTIN            PIC XX.
           05 WS-FS-CONCOUT           PIC XX.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-MOVTO            PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para resumo final                                  *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-TOTAL-LIDOS          PIC 9(5) VALUE ZERO.
           05 WS-TOTAL-CONCILIADOS    PIC 9(5) VALUE ZERO.
           05 WS-TOTAL-REJEITADOS     PIC 9(5) VALUE ZERO.

      *---------------------------------------------------------------*
      * Campo de edicao para formatar valor na saida                  *
      *---------------------------------------------------------------*
       01  WS-VALOR-EDIT              PIC ZZZ.ZZZ.ZZ9,99.

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-PROCESSAR-MOVIMENTOS
           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos de entrada e saida                           *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  MOVTO-IN
           OPEN OUTPUT CONCIL-OUT.

      *---------------------------------------------------------------*
      * Loop principal de leitura do arquivo de movimentos            *
      *---------------------------------------------------------------*
       2000-PROCESSAR-MOVIMENTOS.
           PERFORM UNTIL WS-EOF-MOVTO = 'S'
               READ MOVTO-IN
                   AT END
                       MOVE 'S' TO WS-EOF-MOVTO
                   NOT AT END
                       ADD 1 TO WS-TOTAL-LIDOS
                       PERFORM 2100-VALIDAR-E-CONCILIAR
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Valida o tipo do movimento                                    *
      * Se tipo for invalido, grava rejeicao                          *
      * Se tipo for C ou D, grava como conciliado                     *
      *---------------------------------------------------------------*
       2100-VALIDAR-E-CONCILIAR.
           IF MV-TIPO NOT = 'C'
              AND MV-TIPO NOT = 'D'
               ADD 1 TO WS-TOTAL-REJEITADOS
               MOVE SPACES TO CONCIL-REG
               STRING 'REJEITADO - TIPO INVALIDO - AG '
                      MV-AGENCIA
                      ' CTA '
                      MV-CONTA
                      ' DATA '
                      MV-DATA
                      DELIMITED BY SIZE
                      INTO CONCIL-REG
               END-STRING
               WRITE CONCIL-REG
           ELSE
               ADD 1 TO WS-TOTAL-CONCILIADOS
               MOVE MV-VALOR TO WS-VALOR-EDIT
               MOVE SPACES TO CONCIL-REG
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
               WRITE CONCIL-REG
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo final e fecha os arquivos                        *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO CONCILIACAO ***'
           DISPLAY 'MOVIMENTOS LIDOS       : ' WS-TOTAL-LIDOS
           DISPLAY 'MOVIMENTOS CONCILIADOS : ' WS-TOTAL-CONCILIADOS
           DISPLAY 'MOVIMENTOS REJEITADOS  : ' WS-TOTAL-REJEITADOS

           CLOSE MOVTO-IN
           CLOSE CONCIL-OUT.
