      *===============================================================*
      * PROGRAMA : EBEXTR01                                           *
      * FUNCAO   : GERACAO DO EXTRATO DIARIO DE MOVIMENTOS            *
      * MODULO   : EXTR (Extrato)                                     *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le lancamentos postados (MOVTIN) sequencialmente            *
      * - Para cada movimento, consulta o saldo atual da conta no KSDS*
      * - Monta uma linha de extrato via CPEXT001 e grava em EXTROUT  *
      * - Registra resumo de execucao na trilha de auditoria          *
      *                                                               *
      * ESTRATEGIA DESTA VERSAO:                                      *
      * - Um registro de extrato por movimento processado             *
      * - O saldo gravado no extrato e o saldo ATUAL da conta no KSDS *
      *   (posicao corrente apos todas as postagens do dia)           *
      * - Cada execucao do EBJEXTR gera uma nova geracao do GDG       *
      *                                                               *
      * ENTRADAS:                                                     *
      *   MOVTIN   = Z77948.EMUNAH.ARQ.LANCTO.ESDS  (lancamentos)     *
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS   (master contas)   *
      *                                                               *
      * SAIDAS:                                                       *
      *   EXTROUT  = Z77948.EMUNAH.ARQ.EXTRATO.GDG  (extrato do dia)  *
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ    (trilha)          *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPLCT001 = layout de lancamento (120 bytes)                 *
      *   CPCNT001 = layout de conta      (100 bytes)                 *
      *   CPEXT001 = layout de extrato    (132 bytes)                 *
      *   CPAUD001 = layout de auditoria  (120 bytes)                 *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Extrato gerado com sucesso                      *
      *   RC = 4  --> Nenhum movimento lido (arquivo vazio)           *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBEXTR01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * MOVTO-IN: lancamentos postados, fonte do extrato              *
      * DDNAME: MOVTIN   LRECL: 120   RECFM: FB                       *
      *---------------------------------------------------------------*
           SELECT MOVTO-IN
               ASSIGN TO AS-MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * CONTA-KSDS: consultado para obter saldo atual de cada conta   *
      * Aberto em INPUT  somente leitura, sem alteracao de saldo     *
      * DDNAME: CONTA                                                 *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * EXTRATO-OUT: arquivo GDG de saida com as linhas de extrato    *
      * Aberto em OUTPUT  nova geracao a cada execucao do job        *
      * DDNAME: EXTROUT   LRECL: 132   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT EXTRATO-OUT
               ASSIGN TO EXTROUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-EXTROUT.

      *---------------------------------------------------------------*
      * AUDIT-OUT: trilha de auditoria  registra resumo ao final     *
      * DDNAME: AUDIT   LRECL: 120   RECFM: FB                        *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de movimentos postados  layout via CPLCT001          *
      *---------------------------------------------------------------*
       FD  MOVTO-IN
           RECORD CONTAINS 120 CHARACTERS.
       01  MOVTO-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * KSDS de contas  consultado para obter CNT-SALDO atual        *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de extrato  layout via CPEXT001 (132 bytes)          *
      * Uma linha por movimento processado                            *
      *---------------------------------------------------------------*
       FD  EXTRATO-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  EXTRATO-REG.
           COPY CPEXT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria  layout via CPAUD001                    *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      * '00' = OK   '10' = EOF   '23' = nao encontrado (KSDS)         *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-MOVTIN           PIC XX VALUE SPACES.
              88 FS-MOVTIN-OK        VALUE '00'.
              88 FS-MOVTIN-EOF       VALUE '10'.
           05 WS-FS-CONTA            PIC XX VALUE SPACES.
              88 FS-CONTA-OK         VALUE '00'.
              88 FS-CONTA-NF         VALUE '23'.
           05 WS-FS-EXTROUT          PIC XX VALUE SPACES.
              88 FS-EXTROUT-OK       VALUE '00'.
           05 WS-FS-AUDIT            PIC XX VALUE SPACES.
              88 FS-AUDIT-OK         VALUE '00'.

      *---------------------------------------------------------------*
      * Flags de controle do processamento                            *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-EOF-MOVTIN          PIC X VALUE 'N'.
              88 EOF-MOVTIN          VALUE 'S'.
           05 WS-ERRO                PIC X VALUE 'N'.
              88 COM-ERRO            VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores para resumo final e auditoria                      *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS               PIC 9(9) VALUE ZERO.
           05 WS-GERADOS             PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora capturadas no inicio para uso na auditoria        *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA           PIC 9(8).
       01  WS-HORA-SISTEMA           PIC 9(8).
       01  WS-CHAVE-REF              PIC X(20).

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Ponto de entrada. Processa movimentos, gera extrato e audita  *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME
           PERFORM 1000-ABRIR
           IF NOT COM-ERRO
               PERFORM 2000-PROCESSAR
               PERFORM 3000-AUDITAR-RESUMO
           END-IF
           PERFORM 9000-FECHAR
           PERFORM 9100-RC
           GOBACK.

      *---------------------------------------------------------------*
      * 1000-ABRIR                                                    *
      * Abre todos os arquivos verificando FILE STATUS                *
      * EXTRATO-OUT aberto em OUTPUT para nova geracao do GDG         *
      *---------------------------------------------------------------*
       1000-ABRIR.
           OPEN INPUT MOVTO-IN
           IF NOT FS-MOVTIN-OK
               DISPLAY '*** EBEXTR01 ERRO OPEN MOVTIN - ' WS-FS-MOVTIN
               SET COM-ERRO TO TRUE
           END-IF

           IF NOT COM-ERRO
               OPEN INPUT CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** EBEXTR01 ERRO OPEN CONTA - ' WS-FS-CONTA
                   SET COM-ERRO TO TRUE
               END-IF
           END-IF

           IF NOT COM-ERRO
               OPEN OUTPUT EXTRATO-OUT
               IF NOT FS-EXTROUT-OK
                   DISPLAY '*** EBEXTR01 ERRO OPEN EXTROUT - '
                           WS-FS-EXTROUT
                   SET COM-ERRO TO TRUE
               END-IF
           END-IF

           IF NOT COM-ERRO
               OPEN EXTEND AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** EBEXTR01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
                   SET COM-ERRO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * 2000-PROCESSAR                                                *
      * Loop principal: le um movimento por vez e gera linha extrato  *
      *---------------------------------------------------------------*
       2000-PROCESSAR.
           PERFORM UNTIL EOF-MOVTIN OR COM-ERRO
               READ MOVTO-IN
                   AT END
                       SET EOF-MOVTIN TO TRUE
                   NOT AT END
                       IF FS-MOVTIN-OK
                           ADD 1 TO WS-LIDOS
                           PERFORM 2100-GERAR-LINHA
                       ELSE
                           DISPLAY '*** EBEXTR01 ERRO READ MOVTIN - '
                                   WS-FS-MOVTIN
                           SET COM-ERRO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * 2100-GERAR-LINHA                                              *
      * Consulta o saldo atual da conta no KSDS                       *
      * Se conta nao encontrada, grava saldo zero na linha de extrato *
      * Mapeia campos de CPLCT001 para CPEXT001                       *
      *   LCT-AGENCIA    --> EXT-AGENCIA                              *
      *   LCT-NUM-CONTA  --> EXT-NUM-CONTA                            *
      *   LCT-DATA       --> EXT-DATA-MOVTO                           *
      *   LCT-NSEQ       --> EXT-NSEQ                                 *
      *   LCT-TIPO       --> EXT-TIPO                                 *
      *   LCT-HISTORICO  --> EXT-DESCRICAO                            *
      *   LCT-VALOR      --> EXT-VALOR                                *
      *   CNT-SALDO      --> EXT-SALDO-POSICAO (saldo atual do KSDS)  *
      *   LCT-CANAL      --> EXT-CANAL                                *
      *---------------------------------------------------------------*
       2100-GERAR-LINHA.
           MOVE LCT-CHAVE-CONTA OF MOVTO-REG TO CNT-CHAVE OF CONTA-REG
           READ CONTA-KSDS
               INVALID KEY
                   MOVE ZERO TO CNT-SALDO OF CONTA-REG
               NOT INVALID KEY
                   CONTINUE
           END-READ

           MOVE SPACES TO EXTRATO-REG
           MOVE LCT-AGENCIA   OF MOVTO-REG TO EXT-AGENCIA
           MOVE LCT-NUM-CONTA OF MOVTO-REG TO EXT-NUM-CONTA
           MOVE LCT-DATA      OF MOVTO-REG TO EXT-DATA-MOVTO
           MOVE LCT-NSEQ      OF MOVTO-REG TO EXT-NSEQ
           MOVE LCT-TIPO      OF MOVTO-REG TO EXT-TIPO
           MOVE LCT-HISTORICO OF MOVTO-REG TO EXT-DESCRICAO
           MOVE LCT-VALOR     OF MOVTO-REG TO EXT-VALOR
           MOVE CNT-SALDO     OF CONTA-REG TO EXT-SALDO-POSICAO
           MOVE LCT-CANAL     OF MOVTO-REG TO EXT-CANAL
           WRITE EXTRATO-REG
           IF FS-EXTROUT-OK
               ADD 1 TO WS-GERADOS
           ELSE
               DISPLAY '*** EBEXTR01 ERRO WRITE EXTROUT - '
                       WS-FS-EXTROUT
               SET COM-ERRO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * 3000-AUDITAR-RESUMO                                           *
      * Grava registro unico de auditoria ao final do processamento   *
      * Complemento contem o total de linhas geradas                  *
      *---------------------------------------------------------------*
       3000-AUDITAR-RESUMO.
           MOVE SPACES TO AUDIT-REG
           MOVE 'OK'       TO AU-TIPO-EVENTO
           MOVE 'EBEXTR01' TO AU-PROGRAMA
           MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
           MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
           MOVE 'EXTOK001' TO AU-COD-EVENTO
           MOVE 'EXTRATO-DIA' TO AU-CHAVE-REF
           MOVE 'EXTRATO GERADO COM SUCESSO' TO AU-MENSAGEM
           MOVE WS-GERADOS TO AU-COMPLEMENTO
           WRITE AUDIT-REG.

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      *---------------------------------------------------------------*
       9000-FECHAR.
           CLOSE MOVTO-IN CONTA-KSDS EXTRATO-OUT AUDIT-OUT.

      *---------------------------------------------------------------*
      * 9100-RC                                                       *
      * RC=0: extrato gerado com sucesso                              *
      * RC=4: nenhum movimento no arquivo de entrada                  *
      * RC=8: erro critico de I/O                                     *
      *---------------------------------------------------------------*
       9100-RC.
           DISPLAY '*** EBEXTR01 LIDOS   : ' WS-LIDOS
           DISPLAY '*** EBEXTR01 GERADOS : ' WS-GERADOS
           EVALUATE TRUE
               WHEN COM-ERRO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-LIDOS = ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
