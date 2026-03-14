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
           05 WS-FS-MOVTIN            PIC XX.
           05 WS-FS-CONTA             PIC XX.
           05 WS-FS-AUDIT             PIC XX.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-MOVTO            PIC X VALUE 'N'.

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
      * Campos auxiliares                                             *
      *---------------------------------------------------------------*
       01  WS-VALOR-EDIT              PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-SALDO-ANTES-EDIT        PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-SALDO-DEPOIS-EDIT       PIC ZZZ.ZZZ.ZZ9,99.

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
      * Abre os arquivos necessarios                                  *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  MOVTO-IN
           OPEN I-O    CONTA-KSDS
           OPEN OUTPUT AUDIT-OUT.

      *---------------------------------------------------------------*
      * Loop principal de leitura do arquivo de movimentos            *
      *---------------------------------------------------------------*
       2000-PROCESSAR-MOVIMENTOS.
           PERFORM UNTIL WS-EOF-MOVTO = 'S'
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
      * - valida tipo                                                 *
      * - monta chave da conta                                        *
      * - le a conta no KSDS                                          *
      * - atualiza saldo                                              *
      *---------------------------------------------------------------*
       2100-TRATAR-MOVIMENTO.
           IF MV-TIPO NOT = 'C'
              AND MV-TIPO NOT = 'D'
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
               WRITE AUDIT-REG
           ELSE
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
                       WRITE AUDIT-REG
                   NOT INVALID KEY
                       PERFORM 2200-ATUALIZAR-SALDO
               END-READ
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
                   WRITE AUDIT-REG
               NOT INVALID KEY
                   ADD 1 TO WS-PROCESSADOS
                   MOVE MV-VALOR               TO WS-VALOR-EDIT
                   MOVE WS-SALDO-ANTES-EDIT    TO WS-SALDO-ANTES-EDIT
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
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   WRITE AUDIT-REG
           END-REWRITE.

      *---------------------------------------------------------------*
      * Exibe resumo e fecha os arquivos                              *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO POSTAGEM ***'
           DISPLAY 'LANCAMENTOS LIDOS      : ' WS-LIDOS
           DISPLAY 'LANCAMENTOS PROCESSADOS: ' WS-PROCESSADOS
           DISPLAY 'LANCAMENTOS REJEITADOS : ' WS-REJEITADOS

           CLOSE MOVTO-IN
           CLOSE CONTA-KSDS
           CLOSE AUDIT-OUT.
