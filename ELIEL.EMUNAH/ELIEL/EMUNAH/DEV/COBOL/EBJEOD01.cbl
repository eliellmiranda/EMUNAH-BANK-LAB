      *===============================================================*
      * PROGRAMA : EBJEOD01                                           *
      * FUNCAO   : FECHAMENTO DIARIO (END OF DAY)                     *
      * MODULO   : EOD (End of Day)                                   *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o resultado da conciliacao (CONCIN) e interpreta R11/R31 *
      * - Le o snapshot do dia (SALDOIN) se disponivel                *
      * - Percorre o KSDS de contas somando saldo atual               *
      * - Gera arquivo FECHOUT com resumo do fechamento               *
      * - Grava registro de auditoria com resultado do dia            *
      *                                                               *
      * PAPEL NO FLUXO DO DIA:                                        *
      * - Executado como penultimo step antes da transicao a CLOSED   *
      * - Nao substitui a conciliacao  apenas consolida evidencias   *
      * - Se DIV-CONTAGEM: RC=8, EOD bloqueado                        *
      * - Se DIV-SALDO: RC=4, EOD com alerta (revisao necessaria)     *
      * - Se tudo OK: RC=0, dia apto para CLOSED                      *
      *                                                               *
      * ENTRADAS:                                                     *
      *   CONCIN   = ELIEL.EMUNAH.ARQ.CONCIL.SEQ   (resultado conc.) *
      *   CONTA    = ELIEL.EMUNAH.ARQ.CONTA.KSDS   (master contas)   *
      *   SALDOIN  = ELIEL.EMUNAH.ARQ.SALDO.GDG    (snapshot, opcl.) *
      *                                                               *
      * SAIDAS:                                                       *
      *   FECHOUT  = ELIEL.EMUNAH.ARQ.FECHO.SEQ    (resumo EOD)      *
      *   AUDIT    = ELIEL.EMUNAH.ARQ.AUDIT.SEQ    (trilha)          *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPCNC001 = layout de conciliacao (132 bytes)                *
      *   CPCNT001  = layout de conta       (100 bytes)               *
      *   CPSNP001  = layout de snapshot    (120 bytes)               *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Fechamento OK  dia apto para CLOSED            *
      *   RC = 4  --> Alerta de saldo  revisao recomendada           *
      *   RC = 8  --> Divergencia de contagem ou erro I/O  bloquear  *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBJEOD01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CONCIL-IN: resultado da conciliacao gerado pelo EBCONC01      *
      * Lido para capturar status dos registros R11 e R31             *
      * DDNAME: CONCIN   LRECL: 132   RECFM: FB                       *
      *---------------------------------------------------------------*
           SELECT CONCIL-IN
               ASSIGN TO CONCIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONCIN.

      *---------------------------------------------------------------*
      * CONTA-KSDS: percorrido para somar saldo atual do dia          *
      * ACCESS SEQUENTIAL com READ NEXT                               *
      * DDNAME: CONTA                                                 *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * FECHTO-OUT: arquivo de saida com resumo do fechamento         *
      * DDNAME: FECHOUT   LRECL: 132   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT FECHTO-OUT
               ASSIGN TO FECHOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-FECHOUT.

      *---------------------------------------------------------------*
      * AUDIT-OUT: trilha de auditoria do fechamento                  *
      * DDNAME: AUDIT   LRECL: 128   RECFM: FB                        *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

      *---------------------------------------------------------------*
      * SALDO-IN: snapshot do GDG  arquivo opcional                  *
      * Se ausente, a comparacao de saldo e ignorada                  *
      * DDNAME: SALDOIN   LRECL: 120   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT SALDO-IN
               ASSIGN TO SALDOIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de conciliacao  layout via CPCNC001                 *
      * Lido para identificar registros R11 (contagem) e R31 (saldo)  *
      *---------------------------------------------------------------*
       FD  CONCIL-IN
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  CONCIL-REG.
           COPY CPCNC001.

      *---------------------------------------------------------------*
      * KSDS de contas  lido sequencialmente para soma de saldo      *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de fechamento  texto livre de 132 bytes              *
      * Montado via STRING com linhas descritivas do fechamento       *
      *---------------------------------------------------------------*
       FD  FECHTO-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  FECHTO-REG                PIC X(132).

      *---------------------------------------------------------------*
      * Auditoria  texto livre de 128 bytes                          *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                 PIC X(128).

      *---------------------------------------------------------------*
      * Snapshot  layout via CPSNP001                                *
      *---------------------------------------------------------------*
       FD  SALDO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-REG.
           COPY CPSNP001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CONCIN           PIC XX VALUE SPACES.
              88 FS-CONCIN-OK        VALUE '00'.
              88 FS-CONCIN-EOF       VALUE '10'.
           05 WS-FS-CONTA            PIC XX VALUE SPACES.
              88 FS-CONTA-OK         VALUE '00'.
              88 FS-CONTA-EOF        VALUE '10'.
           05 WS-FS-FECHOUT          PIC XX VALUE SPACES.
              88 FS-FECHOUT-OK       VALUE '00'.
           05 WS-FS-AUDIT            PIC XX VALUE SPACES.
              88 FS-AUDIT-OK         VALUE '00'.
           05 WS-FS-SALDO            PIC XX VALUE SPACES.
              88 FS-SALDO-OK         VALUE '00'.
              88 FS-SALDO-EOF        VALUE '10'.

      *---------------------------------------------------------------*
      * Flags de controle                                             *
      * DIV-CONTAGEM: R11 com status DIVERGENTE (bloqueante RC=8)     *
      * DIV-SALDO: R31 com status DIVERGENTE (alertante RC=4)         *
      * SALDO-DISPONIVEL: SALDOIN aberto com sucesso                  *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-EOF-CONCIN          PIC X VALUE 'N'.
              88 EOF-CONCIN          VALUE 'S'.
           05 WS-EOF-CONTA           PIC X VALUE 'N'.
              88 EOF-CONTA           VALUE 'S'.
           05 WS-EOF-SALDO           PIC X VALUE 'N'.
              88 EOF-SALDO           VALUE 'S'.
           05 WS-ERRO-IO             PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO     VALUE 'S'.
           05 WS-SALDO-DISP          PIC X VALUE 'N'.
              88 SALDO-DISPONIVEL    VALUE 'S'.
           05 WS-DIV-CONTAGEM        PIC X VALUE 'N'.
              88 DIV-CONTAGEM        VALUE 'S'.
           05 WS-DIV-SALDO           PIC X VALUE 'N'.
              88 DIV-SALDO           VALUE 'S'.

      *---------------------------------------------------------------*
      * Totais financeiros para o resumo de fechamento                *
      *---------------------------------------------------------------*
       01  WS-TOTAIS.
           05 WS-TOTAL-SALDO-GDG     PIC S9(15)V99 VALUE ZERO.
           05 WS-TOTAL-SALDO-CONTA   PIC S9(15)V99 VALUE ZERO.
           05 WS-CT-CONTA            PIC 9(9) VALUE ZERO.

       01  WS-DATA-SISTEMA           PIC 9(8).
       01  WS-HORA-SISTEMA           PIC 9(8).
       01  WS-VALOR-EDIT             PIC -Z(10)9,99.

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME
           PERFORM 1000-ABRIR
           IF NOT OCORREU-ERRO-IO
               PERFORM 2000-LER-CONCILIACAO
               PERFORM 3000-LER-SALDO-GDG
               PERFORM 4000-LER-CONTA
               PERFORM 5000-GERAR-FECHAMENTO
               PERFORM 6000-GRAVAR-AUDITORIA
           END-IF
           PERFORM 9000-FECHAR
           PERFORM 9100-RETORNO
           GOBACK.

      *---------------------------------------------------------------*
      * 1000-ABRIR                                                    *
      * SALDOIN e opcional  aviso se ausente, nao aborta             *
      *---------------------------------------------------------------*
       1000-ABRIR.
           OPEN INPUT CONCIL-IN
           IF NOT FS-CONCIN-OK
               DISPLAY '*** EBJEOD01 ERRO OPEN CONCIN - ' WS-FS-CONCIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** EBJEOD01 ERRO OPEN CONTA - ' WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN OUTPUT FECHTO-OUT
               IF NOT FS-FECHOUT-OK
                   DISPLAY '*** EBJEOD01 ERRO OPEN FECHOUT - '
                           WS-FS-FECHOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN EXTEND AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** EBJEOD01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NOT OCORREU-ERRO-IO
               OPEN INPUT SALDO-IN
               IF FS-SALDO-OK
                   SET SALDO-DISPONIVEL TO TRUE
               ELSE
                   DISPLAY '*** EBJEOD01 AVISO - SALDOIN indisponivel.'
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * 2000-LER-CONCILIACAO                                          *
      * Le o CONCIL.SEQ e detecta divergencias nos registros R11/R31  *
      * R11 com 'DIVERGENTE' = problema de contagem (bloqueante)      *
      * R31 com 'DIVERGENTE' = problema de saldo (alertante)          *
      *---------------------------------------------------------------*
       2000-LER-CONCILIACAO.
           PERFORM UNTIL EOF-CONCIN OR OCORREU-ERRO-IO
               READ CONCIL-IN
                   AT END
                       SET EOF-CONCIN TO TRUE
                   NOT AT END
                       IF FS-CONCIN-OK
                           IF CC-TIPO-REG = 'R11'
                              AND CC-STATUS(1:10) = 'DIVERGENTE'
                               SET DIV-CONTAGEM TO TRUE
                           END-IF
                           IF CC-TIPO-REG = 'R31'
                              AND CC-STATUS(1:10) = 'DIVERGENTE'
                               SET DIV-SALDO TO TRUE
                           END-IF
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * 3000-LER-SALDO-GDG                                            *
      * Soma saldos do snapshot GDG para comparacao no FECHOUT        *
      * Ignorado se SALDOIN nao estiver disponivel                    *
      *---------------------------------------------------------------*
       3000-LER-SALDO-GDG.
           IF NOT SALDO-DISPONIVEL
               EXIT PARAGRAPH
           END-IF

           PERFORM UNTIL EOF-SALDO OR OCORREU-ERRO-IO
               READ SALDO-IN
                   AT END
                       SET EOF-SALDO TO TRUE
                   NOT AT END
                       IF FS-SALDO-OK
                           ADD SNP-SALDO TO WS-TOTAL-SALDO-GDG
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * 4000-LER-CONTA                                                *
      * Percorre o KSDS somando saldos atuais e contando contas       *
      *---------------------------------------------------------------*
       4000-LER-CONTA.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-CONTA
                           ADD CNT-SALDO OF CONTA-REG
                               TO WS-TOTAL-SALDO-CONTA
                       ELSE
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * 5000-GERAR-FECHAMENTO                                         *
      * Grava linhas do FECHOUT com resumo do dia                     *
      * Status final determina se o dia pode transitar para CLOSED    *
      *---------------------------------------------------------------*
       5000-GERAR-FECHAMENTO.
           MOVE SPACES TO FECHTO-REG
           STRING 'FECHAMENTO EMUNAH BANK - DATA '
                  WS-DATA-SISTEMA
                  ' HORA '
                  WS-HORA-SISTEMA
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           MOVE WS-TOTAL-SALDO-GDG TO WS-VALOR-EDIT
           STRING 'TOTAL SNAPSHOT GDG : ' WS-VALOR-EDIT
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           MOVE WS-TOTAL-SALDO-CONTA TO WS-VALOR-EDIT
           STRING 'TOTAL POSICAO KSDS : ' WS-VALOR-EDIT
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           STRING 'TOTAL CONTAS LIDAS  : ' WS-CT-CONTA
                  DELIMITED BY SIZE INTO FECHTO-REG
           END-STRING
           WRITE FECHTO-REG

           MOVE SPACES TO FECHTO-REG
           EVALUATE TRUE
               WHEN DIV-CONTAGEM
                   MOVE 'STATUS FECHAMENTO: BLOQUEADO POR DIVERGENCIA'
                       TO FECHTO-REG
               WHEN DIV-SALDO
                   MOVE 'STATUS FECHAMENTO: ALERTA DE SALDO - REVISAO'
                       TO FECHTO-REG
               WHEN OTHER
                   MOVE 'STATUS FECHAMENTO: OK - APTO A FECHAR O DIA'
                       TO FECHTO-REG
           END-EVALUATE
           WRITE FECHTO-REG.

      *---------------------------------------------------------------*
      * 6000-GRAVAR-AUDITORIA                                         *
      * Registra resultado do fechamento na trilha de auditoria       *
      *---------------------------------------------------------------*
       6000-GRAVAR-AUDITORIA.
           MOVE SPACES TO AUDIT-REG
           EVALUATE TRUE
               WHEN DIV-CONTAGEM
                  MOVE 'EBJEOD01 - BLOQUEIO POR DIVERGENCIA DE CONTAGEM'
               TO AUDIT-REG
               WHEN DIV-SALDO
                  MOVE 'EBJEOD01 - ALERTA POR DIVERGENCIA DE SALDO'
                       TO AUDIT-REG
               WHEN OTHER
                  MOVE 'EBJEOD01 - FECHAMENTO OK' TO AUDIT-REG
           END-EVALUATE
           WRITE AUDIT-REG.

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      * SALDO-IN fechado apenas se foi aberto                         *
      *---------------------------------------------------------------*
       9000-FECHAR.
           CLOSE CONCIL-IN
           IF SALDO-DISPONIVEL
               CLOSE SALDO-IN
           END-IF
           CLOSE CONTA-KSDS
           CLOSE FECHTO-OUT
           CLOSE AUDIT-OUT.

      *---------------------------------------------------------------*
      * 9100-RETORNO                                                  *
      * RC=0: dia apto para CLOSED                                    *
      * RC=4: alerta de saldo  revisao recomendada antes de fechar   *
      * RC=8: divergencia de contagem ou erro I/O  nao fechar o dia  *
      *---------------------------------------------------------------*
       9100-RETORNO.
           DISPLAY '*** RESUMO EBJEOD01 ***'
           DISPLAY 'CONTAS: ' WS-CT-CONTA
           DISPLAY 'SALDO GDG : ' WS-TOTAL-SALDO-GDG
           DISPLAY 'SALDO KSDS: ' WS-TOTAL-SALDO-CONTA
           IF OCORREU-ERRO-IO
               MOVE 8 TO RETURN-CODE
           ELSE
               IF DIV-CONTAGEM
                   MOVE 8 TO RETURN-CODE
               ELSE
                   IF DIV-SALDO
                       MOVE 4 TO RETURN-CODE
                   ELSE
                       MOVE 0 TO RETURN-CODE
                   END-IF
               END-IF
           END-IF.
