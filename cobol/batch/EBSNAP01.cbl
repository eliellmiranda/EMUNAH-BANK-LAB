      *===============================================================*
      * PROGRAMA : EBSNAP01                                           *
      * FUNCAO   : GERACAO DO SNAPSHOT DIARIO DE SALDO                *
      * MODULO   : SNAP (Snapshot)                                    *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Percorre todas as contas do KSDS sequencialmente            *
      * - Para cada conta, grava um registro de snapshot via CPSNP001 *
      * - Acumula total de saldo para conferencia no SYSOUT           *
      * - Registra resumo de execucao na trilha de auditoria          *
      *                                                               *
      * PAPEL NO FLUXO DO DIA:                                        *
      * - Executado entre EOTI e EOFI, apos postagem e accruals       *
      * - Gera nova geracao do GDG (DISP=NEW,CATLG no JCL)            *
      * - A geracao gerada e usada pelo EBCONC01 como SALDOIN         *
      * - O EBJEOD01 tambem pode ler o snapshot para verificacao      *
      *                                                               *
      * ENTRADAS:                                                     *
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS   (master contas)   *
      *                                                               *
      * SAIDAS:                                                       *
      *   SALDOUT  = Z77948.EMUNAH.ARQ.SALDO.GDG    (nova geracao)    *
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ    (trilha)          *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPCNT001 = layout de conta    (100 bytes)                   *
      *   CPSNP001 = layout de snapshot (120 bytes)                   *
      *   CPAUD001 = layout de auditoria (120 bytes)                  *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Snapshot gerado com sucesso                     *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBSNAP01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CONTA-KSDS: percorrido via ACCESS SEQUENTIAL + READ NEXT      *
      * Aberto em INPUT — nao altera saldos                           *
      * DDNAME: CONTA                                                 *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * SALDO-OUT: nova geracao do GDG de saldo                       *
      * Aberto em OUTPUT — cada execucao gera uma geracao nova        *
      * DDNAME: SALDOUT   LRECL: 120   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT SALDO-OUT
               ASSIGN TO SALDOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

      *---------------------------------------------------------------*
      * AUDIT-OUT: trilha de auditoria com resumo do snapshot         *
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
      * KSDS de contas — lido sequencialmente para gerar o snapshot   *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de snapshot — layout via CPSNP001 (120 bytes)         *
      * Um registro por conta do KSDS                                 *
      *---------------------------------------------------------------*
       FD  SALDO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-REG.
           COPY CPSNP001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria — layout via CPAUD001                    *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status dos arquivos                                      *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CONTA            PIC XX VALUE SPACES.
              88 FS-CONTA-OK         VALUE '00'.
              88 FS-CONTA-EOF        VALUE '10'.
           05 WS-FS-SALDO            PIC XX VALUE SPACES.
              88 FS-SALDO-OK         VALUE '00'.
           05 WS-FS-AUDIT            PIC XX VALUE SPACES.
              88 FS-AUDIT-OK         VALUE '00'.

      *---------------------------------------------------------------*
      * Flags de controle                                             *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-EOF-CONTA           PIC X VALUE 'N'.
              88 EOF-CONTA           VALUE 'S'.
           05 WS-ERRO                PIC X VALUE 'N'.
              88 COM-ERRO            VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores e acumulador de saldo total                        *
      * WS-TOTAL-SALDO exibido no SYSOUT para conferencia rapida      *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CT-LIDAS            PIC 9(9) VALUE ZERO.
           05 WS-CT-GERADAS          PIC 9(9) VALUE ZERO.
       01  WS-TOTAL-SALDO            PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora capturadas no inicio                              *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA           PIC 9(8).
       01  WS-HORA-SISTEMA           PIC 9(8).

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME
           PERFORM 1000-ABRIR
           IF NOT COM-ERRO
               PERFORM 2000-PROCESSAR
               PERFORM 3000-AUDITAR
           END-IF
           PERFORM 9000-FECHAR
           PERFORM 9100-RC
           GOBACK.

      *---------------------------------------------------------------*
      * 1000-ABRIR                                                    *
      * SALDO-OUT aberto em OUTPUT — nova geracao do GDG por execucao *
      *---------------------------------------------------------------*
       1000-ABRIR.
           OPEN INPUT CONTA-KSDS
           IF NOT FS-CONTA-OK
               DISPLAY '*** EBSNAP01 ERRO OPEN CONTA - ' WS-FS-CONTA
               SET COM-ERRO TO TRUE
           END-IF

           IF NOT COM-ERRO
               OPEN OUTPUT SALDO-OUT
               IF NOT FS-SALDO-OK
                   DISPLAY '*** EBSNAP01 ERRO OPEN SALDOUT - '
                           WS-FS-SALDO
                   SET COM-ERRO TO TRUE
               END-IF
           END-IF

           IF NOT COM-ERRO
               OPEN EXTEND AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** EBSNAP01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
                   SET COM-ERRO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * 2000-PROCESSAR                                                *
      * Le cada conta do KSDS via READ NEXT e grava registro snapshot *
      * Mapeamento de campos:                                         *
      *   CNT-AGENCIA    --> SNP-AGENCIA                              *
      *   CNT-NUM-CONTA  --> SNP-NUM-CONTA                            *
      *   CNT-SALDO      --> SNP-SALDO                                *
      *   WS-DATA-SISTEMA--> SNP-DATA                                 *
      *---------------------------------------------------------------*
       2000-PROCESSAR.
           PERFORM UNTIL EOF-CONTA OR COM-ERRO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-LIDAS
                           MOVE CNT-AGENCIA   OF CONTA-REG
                               TO SNP-AGENCIA
                           MOVE CNT-NUM-CONTA OF CONTA-REG
                               TO SNP-NUM-CONTA
                           MOVE CNT-SALDO     OF CONTA-REG
                               TO SNP-SALDO
                           MOVE WS-DATA-SISTEMA
                               TO SNP-DATA
                           WRITE SALDO-REG
                           IF FS-SALDO-OK
                               ADD 1 TO WS-CT-GERADAS
                               ADD CNT-SALDO OF CONTA-REG
                                   TO WS-TOTAL-SALDO
                           ELSE
                               DISPLAY '*** EBSNAP01 ERRO WRITE '
                                       'SALDOUT - ' WS-FS-SALDO
                               SET COM-ERRO TO TRUE
                           END-IF
                       ELSE
                           DISPLAY '*** EBSNAP01 ERRO READ CONTA - '
                                   WS-FS-CONTA
                           SET COM-ERRO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * 3000-AUDITAR                                                  *
      * Grava registro unico de auditoria com resumo do snapshot      *
      * Complemento contem o total de registros gerados               *
      *---------------------------------------------------------------*
       3000-AUDITAR.
           MOVE SPACES TO AUDIT-REG
           MOVE 'OK'       TO AU-TIPO-EVENTO
           MOVE 'EBSNAP01' TO AU-PROGRAMA
           MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
           MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
           MOVE 'SNAPOK001' TO AU-COD-EVENTO
           MOVE 'SNAPSHOT-DIARIO' TO AU-CHAVE-REF
           MOVE 'SNAPSHOT DE SALDO GERADO' TO AU-MENSAGEM
           MOVE WS-CT-GERADAS TO AU-COMPLEMENTO
           WRITE AUDIT-REG.

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      *---------------------------------------------------------------*
       9000-FECHAR.
           CLOSE CONTA-KSDS SALDO-OUT AUDIT-OUT.

      *---------------------------------------------------------------*
      * 9100-RC                                                       *
      * Exibe totais no SYSOUT — WS-TOTAL-SALDO permite conferencia   *
      * com o somatorio do EBCONC01                                   *
      *---------------------------------------------------------------*
       9100-RC.
           DISPLAY '*** EBSNAP01 CONTAS LIDAS   : ' WS-CT-LIDAS
           DISPLAY '*** EBSNAP01 REGS GERADOS   : ' WS-CT-GERADAS
           DISPLAY '*** EBSNAP01 TOTAL DE SALDO : ' WS-TOTAL-SALDO
           IF COM-ERRO
               MOVE 8 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.