       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBPOST01.

      *===============================================================*
      * PROGRAMA: EBPOST01                                            *
      * FUNCAO : POSTAR MOVIMENTOS NAS CONTAS                         *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le um arquivo sequencial de lancamentos/movimentos          *
      * - Localiza a conta no arquivo KSDS de contas                  *
      * - Atualiza o saldo conforme o tipo do movimento               *
      *   C = Credito  /  D = Debito                                  *
      * - Grava um arquivo de auditoria com sucessos e rejeicoes      *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular a etapa batch de postagem financeira                *
      * - Aplicar movimentacoes no cadastro de contas                 *
      * - Produzir trilha de auditoria para conferencias              *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      *---------------------------------------------------------------*
      * MOVTO-IN = arquivo de entrada com os movimentos do dia        *
      * Ex.: creditos, debitos, ajustes                               *
      *---------------------------------------------------------------*
           SELECT MOVTO-IN
               ASSIGN TO MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * CONTA-KSDS = arquivo master de contas                         *
      * Aqui buscamos a conta e atualizamos o saldo                   *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * AUDIT-OUT = arquivo sequencial de auditoria                   *
      * Guarda mensagens de processamento e rejeicoes                 *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de movimentos                               *
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
      * Arquivo KSDS de contas                                        *
      * O copybook CPCNT001 deve conter os campos da conta            *
      * incluindo a chave CNT-CHAVE e o saldo CNT-SALDO               *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria                                          *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Area para armazenar os file status dos arquivos               *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-MOVTIN            PIC XX VALUE SPACES.
           05 WS-FS-CONTA             PIC XX VALUE SPACES.
           05 WS-FS-AUDIT             PIC XX VALUE SPACES.

      *---------------------------------------------------------------*
      * Controle de processamento                                     *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-MOVTO            PIC X VALUE 'N'.
              88 FIM-MOVTO                 VALUE 'S'.
           05 WS-FALHA-INICIALIZACAO PIC X VALUE 'N'.
           05 WS-MOVTO-ABERTO        PIC X VALUE 'N'.
           05 WS-CONTA-ABERTO        PIC X VALUE 'N'.
           05 WS-AUDIT-ABERTO        PIC X VALUE 'N'.
           05 WS-MOVIMENTO-VALIDO    PIC X VALUE 'S'.
              88 MOVIMENTO-OK             VALUE 'S'.
              88 MOVIMENTO-ERRO           VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para resumo final                                  *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(5) VALUE ZERO.
           05 WS-PROCESSADOS          PIC 9(5) VALUE ZERO.
           05 WS-REJEITADOS           PIC 9(5) VALUE ZERO.

      *---------------------------------------------------------------*
      * Chave montada a partir do movimento para localizar a conta    *
      *---------------------------------------------------------------*
       01  WS-CHAVE-CONTA.
           05 WS-AGENCIA              PIC 9(4).
           05 WS-NUM-CONTA            PIC 9(8).

      *---------------------------------------------------------------*
      * Campos auxiliares para exibicao em auditoria                  *
      *---------------------------------------------------------------*
       01  WS-AREAS-EDICAO.
           05 WS-VALOR-EDIT           PIC ZZZ.ZZZ.ZZZ.ZZ9,99.
           05 WS-SALDO-ANTES-EDIT     PIC -ZZZ.ZZZ.ZZZ.ZZ9,99.
           05 WS-SALDO-DEPOIS-EDIT    PIC -ZZZ.ZZZ.ZZZ.ZZ9,99.

       PROCEDURE DIVISION.

      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS

           IF WS-FALHA-INICIALIZACAO = 'N'
               PERFORM 2000-PROCESSAR-MOVIMENTOS
           END-IF

           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos necessarios e valida os file status          *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT MOVTO-IN
           IF WS-FS-MOVTIN = '00'
               MOVE 'S' TO WS-MOVTO-ABERTO
           ELSE
               MOVE 'S' TO WS-FALHA-INICIALIZACAO
               DISPLAY 'ERRO OPEN MOVTO-IN. FS=' WS-FS-MOVTIN
           END-IF

           IF WS-FALHA-INICIALIZACAO = 'N'
               OPEN I-O CONTA-KSDS
               IF WS-FS-CONTA = '00'
                   MOVE 'S' TO WS-CONTA-ABERTO
               ELSE
                   MOVE 'S' TO WS-FALHA-INICIALIZACAO
                   DISPLAY 'ERRO OPEN CONTA-KSDS. FS=' WS-FS-CONTA
               END-IF
           END-IF

           IF WS-FALHA-INICIALIZACAO = 'N'
               OPEN OUTPUT AUDIT-OUT
               IF WS-FS-AUDIT = '00'
                   MOVE 'S' TO WS-AUDIT-ABERTO
               ELSE
                   MOVE 'S' TO WS-FALHA-INICIALIZACAO
                   DISPLAY 'ERRO OPEN AUDIT-OUT. FS=' WS-FS-AUDIT
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Loop principal de leitura do arquivo de movimentos            *
      *---------------------------------------------------------------*
       2000-PROCESSAR-MOVIMENTOS.
           PERFORM UNTIL FIM-MOVTO
               READ MOVTO-IN
                   AT END
                       MOVE 'S' TO WS-EOF-MOVTO
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       PERFORM 2100-TRATAR-MOVIMENTO
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Trata cada movimento lido                                     *
      * - valida dados basicos                                        *
      * - monta chave da conta                                        *
      * - le a conta no KSDS                                          *
      * - atualiza saldo                                              *
      *---------------------------------------------------------------*
       2100-TRATAR-MOVIMENTO.
           SET MOVIMENTO-OK TO TRUE

           PERFORM 2110-VALIDAR-MOVIMENTO

           IF MOVIMENTO-OK
               MOVE MV-AGENCIA TO WS-AGENCIA
               MOVE MV-CONTA   TO WS-NUM-CONTA

      *        Move a chave montada para a chave do registro de conta
               MOVE WS-CHAVE-CONTA TO CNT-CHAVE OF CONTA-REG

      *        Tenta localizar a conta no arquivo KSDS
               READ CONTA-KSDS
                   INVALID KEY
                       ADD 1 TO WS-REJEITADOS
                       MOVE SPACES TO AUDIT-REG
                       STRING 'REJEITADO - CONTA NAO ENCONTRADA - AG '
                              MV-AGENCIA
                              ' CTA '
                              MV-CONTA
                              DELIMITED BY SIZE
                              INTO AUDIT-REG
                       END-STRING
                       PERFORM 7000-GRAVAR-AUDITORIA
                       SET MOVIMENTO-ERRO TO TRUE
                   NOT INVALID KEY
                       PERFORM 2200-ATUALIZAR-SALDO
               END-READ
           END-IF.

      *---------------------------------------------------------------*
      * Valida o movimento antes da tentativa de postagem             *
      * OBS.: Mesmo que haja etapa anterior de validacao, manter      *
      * esta protecao aqui ajuda na robustez do batch                 *
      *---------------------------------------------------------------*
       2110-VALIDAR-MOVIMENTO.
           IF MV-TIPO NOT = 'C'
              AND MV-TIPO NOT = 'D'
               SET MOVIMENTO-ERRO TO TRUE
               ADD 1 TO WS-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'REJEITADO - TIPO INVALIDO - AG '
                      MV-AGENCIA
                      ' CTA '
                      MV-CONTA
                      ' DATA '
                      MV-DATA
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               PERFORM 7000-GRAVAR-AUDITORIA
           ELSE
               IF MV-AGENCIA = ZERO
                  OR MV-CONTA = ZERO
                   SET MOVIMENTO-ERRO TO TRUE
                   ADD 1 TO WS-REJEITADOS
                   MOVE SPACES TO AUDIT-REG
                   STRING 'REJEITADO - CHAVE INVALIDA - AG '
                          MV-AGENCIA
                          ' CTA '
                          MV-CONTA
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   PERFORM 7000-GRAVAR-AUDITORIA
               ELSE
                   IF MV-VALOR <= ZERO
                       SET MOVIMENTO-ERRO TO TRUE
                       ADD 1 TO WS-REJEITADOS
                       MOVE SPACES TO AUDIT-REG
                       STRING 'REJEITADO - VALOR INVALIDO - AG '
                              MV-AGENCIA
                              ' CTA '
                              MV-CONTA
                              DELIMITED BY SIZE
                              INTO AUDIT-REG
                       END-STRING
                       PERFORM 7000-GRAVAR-AUDITORIA
                   END-IF
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Atualiza o saldo da conta conforme o tipo do movimento        *
      * C = soma no saldo                                             *
      * D = subtrai do saldo                                          *
      * Depois regrava o registro no KSDS                             *
      *---------------------------------------------------------------*
       2200-ATUALIZAR-SALDO.
           MOVE CNT-SALDO OF CONTA-REG TO WS-SALDO-ANTES-EDIT

           EVALUATE MV-TIPO
               WHEN 'C'
                   ADD MV-VALOR TO CNT-SALDO OF CONTA-REG
               WHEN 'D'
                   SUBTRACT MV-VALOR FROM CNT-SALDO OF CONTA-REG
           END-EVALUATE

           REWRITE CONTA-REG
               INVALID KEY
                   ADD 1 TO WS-REJEITADOS
                   MOVE SPACES TO AUDIT-REG
                   STRING 'REJEITADO - ERRO REWRITE - AG '
                          MV-AGENCIA
                          ' CTA '
                          MV-CONTA
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   PERFORM 7000-GRAVAR-AUDITORIA
               NOT INVALID KEY
                   ADD 1 TO WS-PROCESSADOS
                   MOVE MV-VALOR TO WS-VALOR-EDIT
                   MOVE CNT-SALDO OF CONTA-REG TO WS-SALDO-DEPOIS-EDIT
                   MOVE SPACES TO AUDIT-REG
                   STRING 'POSTADO - AG '
                          MV-AGENCIA
                          ' CTA '
                          MV-CONTA
                          ' TIPO '
                          MV-TIPO
                          ' VALOR '
                          WS-VALOR-EDIT
                          ' SALDO ANT '
                          WS-SALDO-ANTES-EDIT
                          ' SALDO DEP '
                          WS-SALDO-DEPOIS-EDIT
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   PERFORM 7000-GRAVAR-AUDITORIA
           END-REWRITE.

      *---------------------------------------------------------------*
      * Centraliza a gravacao do arquivo de auditoria                 *
      *---------------------------------------------------------------*
       7000-GRAVAR-AUDITORIA.
           WRITE AUDIT-REG
           IF WS-FS-AUDIT NOT = '00'
               DISPLAY 'ERRO WRITE AUDIT-OUT. FS=' WS-FS-AUDIT
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo e fecha os arquivos                              *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO POSTAGEM ***'
           DISPLAY 'LANCAMENTOS LIDOS      : ' WS-LIDOS
           DISPLAY 'LANCAMENTOS PROCESSADOS: ' WS-PROCESSADOS
           DISPLAY 'LANCAMENTOS REJEITADOS : ' WS-REJEITADOS

           IF WS-MOVTO-ABERTO = 'S'
               CLOSE MOVTO-IN
           END-IF

           IF WS-CONTA-ABERTO = 'S'
               CLOSE CONTA-KSDS
           END-IF

           IF WS-AUDIT-ABERTO = 'S'
               CLOSE AUDIT-OUT
           END-IF.