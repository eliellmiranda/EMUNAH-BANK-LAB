       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBACCR01.
      *===============================================================*
      * PROGRAMA : EBACCR01                                           *
      * FUNCAO   : ACCRUALS - JUROS E TARIFAS                         *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le PARM.JUROS.CONFIG para carregar taxas e tarifas          *
      * - Percorre CONTA.KSDS (I-O) sequencialmente                   *
      * - Para cada conta ATIVA:                                      *
      *     . Calcula juros (se SALDO > 0 e taxa > 0)                 *
      *     . Aplica tarifa mensal (se tarifa > 0)                    *
      *     . Atualiza CNT-SALDO via REWRITE                          *
      *     . Grava movimento em ARQ.ACCR.MOV.SEQ                     *
      *     . Apenda movimento em ARQ.LANCTO.ESDS                     *
      * - Contas INATIVAS e BLOQUEADAS sao ignoradas                  *
      * - Grava registro de auditoria ao final                        *
      *                                                               *
      * LAYOUT PARM.JUROS.CONFIG (80 bytes, LRECL=80):                *
      *   POS 1   : tipo de parametro  J=juros  T=tarifa  *=comentario*
      *   POS 2   : tipo de conta      C=corrente  P=poupanca          *
      *   POS 3-7 : valor  PIC 9(3)V99  ex: 00050 = 0.50%  01250=12.50*
      *   POS 8-80: FILLER / descricao livre                          *
      *                                                               *
      * EXEMPLO DE PARM.JUROS.CONFIG:                                  *
      *   JC00000  JUROS CORRENTE - ISENTO                            *
      *   JP00050  JUROS POUPANCA - 0.50% AO MES                      *
      *   TC01250  TARIFA CORRENTE - R$ 12.50 AO MES                  *
      *   TP00000  TARIFA POUPANCA - ISENTA                           *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Processamento OK                                *
      *   RC = 4  --> Nenhuma conta processada (KSDS vazio)           *
      *   RC = 8  --> Erro critico de I/O ou PARM invalido            *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * PARMLIB = arquivo de parametros de juros e tarifas            *
      *---------------------------------------------------------------*
           SELECT PARM-IN
               ASSIGN TO PARMLIB
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-PARM.

      *---------------------------------------------------------------*
      * CONTA = KSDS de contas - aberto I-O para REWRITE               *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * ACCROUT = movimentos de accrual do dia                        *
      *---------------------------------------------------------------*
           SELECT ACCR-OUT
               ASSIGN TO ACCROUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ACCR.

      *---------------------------------------------------------------*
      * LANCTO = ESDS de lancamentos (DISP=MOD/EXTEND no JCL)         *
      *---------------------------------------------------------------*
           SELECT LANCTO-ESDS
               ASSIGN TO LANCTO
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-LANCTO.

      *---------------------------------------------------------------*
      * AUDIT = trilha de auditoria (DISP=MOD no JCL)                 *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de parametros (80 bytes)                              *
      *---------------------------------------------------------------*
       FD  PARM-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  PARM-REG.
           05 PARM-TIPO               PIC X(1).
           05 PARM-CONTA-TIPO         PIC X(1).
           05 PARM-VALOR              PIC 9(3)V99.
           05 FILLER                  PIC X(73).

      *---------------------------------------------------------------*
      * KSDS de contas (layout via CPCNT001)                          *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Movimentos de accrual (120 bytes - mesmo layout LANCTO.ESDS)  *
      *---------------------------------------------------------------*
       FD  ACCR-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ACCR-REG.
           05 ACR-AGENCIA             PIC X(4).
           05 ACR-NUM-CONTA           PIC X(8).
           05 ACR-DATA                PIC X(8).
           05 ACR-TIPO                PIC X(1).
           05 ACR-VALOR               PIC 9(11)V99.
           05 ACR-HISTORICO           PIC X(30).
           05 ACR-CANAL               PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * ESDS de lancamentos (append de movimentos de accrual)         *
      *---------------------------------------------------------------*
       FD  LANCTO-ESDS
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  LANCTO-REG                 PIC X(120).

      *---------------------------------------------------------------*
      * Auditoria (120 bytes)                                         *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status                                                   *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-PARM              PIC XX VALUE SPACES.
              88 FS-PARM-OK           VALUE '00'.
              88 FS-PARM-EOF          VALUE '10'.
           05 WS-FS-CONTA             PIC XX VALUE SPACES.
              88 FS-CONTA-OK          VALUE '00'.
              88 FS-CONTA-EOF         VALUE '10'.
           05 WS-FS-ACCR              PIC XX VALUE SPACES.
              88 FS-ACCR-OK           VALUE '00'.
           05 WS-FS-LANCTO            PIC XX VALUE SPACES.
              88 FS-LANCTO-OK         VALUE '00'.
           05 WS-FS-AUDIT             PIC XX VALUE SPACES.
              88 FS-AUDIT-OK          VALUE '00'.

      *---------------------------------------------------------------*
      * Controles de EOF e flags                                      *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-PARM             PIC X VALUE 'N'.
              88 EOF-PARM             VALUE 'S'.
           05 WS-EOF-CONTA            PIC X VALUE 'N'.
              88 EOF-CONTA            VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.
           05 WS-PARM-CARREGADO       PIC X VALUE 'N'.
              88 PARM-CARREGADO       VALUE 'S'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ABERTOS.
           05 WS-PARM-ABERTO          PIC X VALUE 'N'.
              88 PARM-ABERTO          VALUE 'S'.
           05 WS-CONTA-ABERTO         PIC X VALUE 'N'.
              88 CONTA-ABERTO         VALUE 'S'.
           05 WS-ACCR-ABERTO          PIC X VALUE 'N'.
              88 ACCR-ABERTO          VALUE 'S'.
           05 WS-LANCTO-ABERTO        PIC X VALUE 'N'.
              88 LANCTO-ABERTO        VALUE 'S'.
           05 WS-AUDIT-ABERTO         PIC X VALUE 'N'.
              88 AUDIT-ABERTO         VALUE 'S'.

      *---------------------------------------------------------------*
      * Taxas e tarifas carregadas do PARM                            *
      *---------------------------------------------------------------*
       01  WS-PARAMETROS.
           05 WS-TAXA-JUROS-CORRENTE  PIC 9(3)V99 VALUE ZERO.
           05 WS-TAXA-JUROS-POUPANCA  PIC 9(3)V99 VALUE ZERO.
           05 WS-TARIFA-CORRENTE      PIC 9(3)V99 VALUE ZERO.
           05 WS-TARIFA-POUPANCA      PIC 9(3)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Valores calculados para o registro atual                      *
      *---------------------------------------------------------------*
       01  WS-CALC.
           05 WS-JUROS-VALOR          PIC S9(11)V99 VALUE ZERO.
           05 WS-TARIFA-VALOR         PIC S9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Contadores                                                    *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CT-LIDAS             PIC 9(9) VALUE ZERO.
           05 WS-CT-PROCESSADAS       PIC 9(9) VALUE ZERO.
           05 WS-CT-IGNORADAS         PIC 9(9) VALUE ZERO.
           05 WS-CT-MOV-GERADOS       PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Totalizadores                                                 *
      *---------------------------------------------------------------*
       01  WS-TOTAIS.
           05 WS-TOTAL-JUROS          PIC S9(15)V99 VALUE ZERO.
           05 WS-TOTAL-TARIFAS        PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora do sistema                                        *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA            PIC 9(8).
       01  WS-HORA-SISTEMA            PIC 9(8).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME

           PERFORM 1000-ABRIR-ARQUIVOS

           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-CARREGAR-PARAMETROS
           END-IF

           IF NAO-OCORREU-ERRO-IO AND PARM-CARREGADO
               PERFORM 3000-PROCESSAR-CONTAS
               PERFORM 4000-GRAVAR-AUDITORIA
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre todos os arquivos                                        *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT PARM-IN
           IF FS-PARM-OK
               SET PARM-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN PARM-IN - STATUS: '
                       WS-FS-PARM
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN I-O CONTA-KSDS
               IF FS-CONTA-OK
                   SET CONTA-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT ACCR-OUT
               IF FS-ACCR-OK
                   SET ACCR-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN ACCR-OUT - STATUS: '
                           WS-FS-ACCR
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN EXTEND LANCTO-ESDS
               IF FS-LANCTO-OK
                   SET LANCTO-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN LANCTO-ESDS - STATUS: '
                           WS-FS-LANCTO
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
      * Le PARM.JUROS.CONFIG e carrega as 4 taxas/tarifas             *
      * Registros com * na posicao 1 sao comentarios e ignorados      *
      *---------------------------------------------------------------*
       2000-CARREGAR-PARAMETROS.
           PERFORM UNTIL EOF-PARM OR OCORREU-ERRO-IO
               READ PARM-IN
                   AT END
                       SET EOF-PARM TO TRUE
                   NOT AT END
                       IF FS-PARM-OK
                           IF PARM-TIPO NOT = '*'
                               PERFORM 2100-INTERPRETAR-PARM
                           END-IF
                       ELSE
                           DISPLAY '*** ERRO READ PARM-IN - STATUS: '
                                   WS-FS-PARM
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM

           IF NAO-OCORREU-ERRO-IO
               SET PARM-CARREGADO TO TRUE
               DISPLAY '*** PARAMETROS CARREGADOS:'
               DISPLAY 'JUROS  CORRENTE  : ' WS-TAXA-JUROS-CORRENTE
                       '% a.m.'
               DISPLAY 'JUROS  POUPANCA  : ' WS-TAXA-JUROS-POUPANCA
                       '% a.m.'
               DISPLAY 'TARIFA CORRENTE  : R$' WS-TARIFA-CORRENTE
               DISPLAY 'TARIFA POUPANCA  : R$' WS-TARIFA-POUPANCA
           END-IF.

      *---------------------------------------------------------------*
      * Interpreta uma linha do PARM e carrega a variavel correta     *
      *---------------------------------------------------------------*
       2100-INTERPRETAR-PARM.
           EVALUATE TRUE
               WHEN PARM-TIPO = 'J' AND PARM-CONTA-TIPO = 'C'
                   MOVE PARM-VALOR TO WS-TAXA-JUROS-CORRENTE
               WHEN PARM-TIPO = 'J' AND PARM-CONTA-TIPO = 'P'
                   MOVE PARM-VALOR TO WS-TAXA-JUROS-POUPANCA
               WHEN PARM-TIPO = 'T' AND PARM-CONTA-TIPO = 'C'
                   MOVE PARM-VALOR TO WS-TARIFA-CORRENTE
               WHEN PARM-TIPO = 'T' AND PARM-CONTA-TIPO = 'P'
                   MOVE PARM-VALOR TO WS-TARIFA-POUPANCA
               WHEN OTHER
                   DISPLAY '*** AVISO: PARM IGNORADO TIPO='
                           PARM-TIPO ' CONTA=' PARM-CONTA-TIPO
           END-EVALUATE.

      *---------------------------------------------------------------*
      * Percorre CONTA.KSDS e aplica accruals em contas ativas        *
      *---------------------------------------------------------------*
       3000-PROCESSAR-CONTAS.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-LIDAS
                           EVALUATE CNT-STATUS OF CONTA-REG
                               WHEN 'A'
                                   PERFORM 3100-CALCULAR-E-APLICAR
                               WHEN OTHER
                                   ADD 1 TO WS-CT-IGNORADAS
                           END-EVALUATE
                       ELSE
                           DISPLAY '*** ERRO READ CONTA-KSDS - '
                                   WS-FS-CONTA
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Calcula juros e tarifa e aplica na conta                      *
      *---------------------------------------------------------------*
       3100-CALCULAR-E-APLICAR.
           MOVE ZERO TO WS-JUROS-VALOR
                        WS-TARIFA-VALOR

      *    Calcula juros conforme tipo de conta (so se saldo positivo)
           EVALUATE CNT-TIPO OF CONTA-REG
               WHEN 'C'
                   IF WS-TAXA-JUROS-CORRENTE > ZERO
                      AND CNT-SALDO OF CONTA-REG > ZERO
                       COMPUTE WS-JUROS-VALOR ROUNDED =
                           CNT-SALDO OF CONTA-REG *
                           WS-TAXA-JUROS-CORRENTE / 100
                   END-IF
                   MOVE WS-TARIFA-CORRENTE TO WS-TARIFA-VALOR
               WHEN 'P'
                   IF WS-TAXA-JUROS-POUPANCA > ZERO
                      AND CNT-SALDO OF CONTA-REG > ZERO
                       COMPUTE WS-JUROS-VALOR ROUNDED =
                           CNT-SALDO OF CONTA-REG *
                           WS-TAXA-JUROS-POUPANCA / 100
                   END-IF
                   MOVE WS-TARIFA-POUPANCA TO WS-TARIFA-VALOR
               WHEN OTHER
      *            Tipo desconhecido: ignora sem erro
                   ADD 1 TO WS-CT-IGNORADAS
                   EXIT PARAGRAPH
           END-EVALUATE

      *    Atualiza o saldo da conta
           IF WS-JUROS-VALOR > ZERO
               ADD WS-JUROS-VALOR TO CNT-SALDO OF CONTA-REG
           END-IF
           IF WS-TARIFA-VALOR > ZERO
               SUBTRACT WS-TARIFA-VALOR FROM CNT-SALDO OF CONTA-REG
           END-IF

      *    Persiste o REWRITE no KSDS
           REWRITE CONTA-REG
           IF NOT FS-CONTA-OK
               DISPLAY '*** ERRO REWRITE CONTA-KSDS AG='
                       CNT-AGENCIA OF CONTA-REG
                       ' CTA=' CNT-NUM-CONTA OF CONTA-REG
                       ' STATUS=' WS-FS-CONTA
               SET OCORREU-ERRO-IO TO TRUE
               EXIT PARAGRAPH
           END-IF

           ADD 1 TO WS-CT-PROCESSADAS

      *    Grava movimento de juros (se houver)
           IF WS-JUROS-VALOR > ZERO
               PERFORM 3200-GRAVAR-MOVIMENTO-JUROS
           END-IF

      *    Grava movimento de tarifa (se houver)
           IF WS-TARIFA-VALOR > ZERO
               PERFORM 3300-GRAVAR-MOVIMENTO-TARIFA
           END-IF.

      *---------------------------------------------------------------*
      * Grava movimento de credito de juros                           *
      *---------------------------------------------------------------*
       3200-GRAVAR-MOVIMENTO-JUROS.
           MOVE SPACES       TO ACCR-REG
           MOVE CNT-AGENCIA  OF CONTA-REG TO ACR-AGENCIA
           MOVE CNT-NUM-CONTA OF CONTA-REG TO ACR-NUM-CONTA
           MOVE WS-DATA-SISTEMA            TO ACR-DATA
           MOVE 'C'                        TO ACR-TIPO
           MOVE WS-JUROS-VALOR             TO ACR-VALOR
           MOVE 'ACCRUAL JUROS MENSAIS'    TO ACR-HISTORICO
           MOVE 'BATCH-ACCR'               TO ACR-CANAL

           PERFORM 3900-GRAVAR-NOS-DOIS-DESTINOS
           ADD WS-JUROS-VALOR TO WS-TOTAL-JUROS.

      *---------------------------------------------------------------*
      * Grava movimento de debito de tarifa                           *
      *---------------------------------------------------------------*
       3300-GRAVAR-MOVIMENTO-TARIFA.
           MOVE SPACES        TO ACCR-REG
           MOVE CNT-AGENCIA   OF CONTA-REG TO ACR-AGENCIA
           MOVE CNT-NUM-CONTA OF CONTA-REG TO ACR-NUM-CONTA
           MOVE WS-DATA-SISTEMA            TO ACR-DATA
           MOVE 'D'                        TO ACR-TIPO
           MOVE WS-TARIFA-VALOR            TO ACR-VALOR
           MOVE 'TARIFA MENSAL SERVICOS'   TO ACR-HISTORICO
           MOVE 'BATCH-ACCR'               TO ACR-CANAL

           PERFORM 3900-GRAVAR-NOS-DOIS-DESTINOS
           ADD WS-TARIFA-VALOR TO WS-TOTAL-TARIFAS.

      *---------------------------------------------------------------*
      * Grava o registro em ACCR.MOV.SEQ e em LANCTO.ESDS             *
      *---------------------------------------------------------------*
       3900-GRAVAR-NOS-DOIS-DESTINOS.
           WRITE ACCR-REG
           IF NOT FS-ACCR-OK
               DISPLAY '*** ERRO WRITE ACCR-OUT - STATUS: '
                       WS-FS-ACCR
               SET OCORREU-ERRO-IO TO TRUE
               EXIT PARAGRAPH
           END-IF

           MOVE ACCR-REG TO LANCTO-REG
           WRITE LANCTO-REG
           IF NOT FS-LANCTO-OK
               DISPLAY '*** ERRO WRITE LANCTO-ESDS - STATUS: '
                       WS-FS-LANCTO
               SET OCORREU-ERRO-IO TO TRUE
               EXIT PARAGRAPH
           END-IF

           ADD 1 TO WS-CT-MOV-GERADOS.

      *---------------------------------------------------------------*
      * Grava registro de auditoria do accrual                        *
      *---------------------------------------------------------------*
       4000-GRAVAR-AUDITORIA.
           MOVE SPACES TO AUDIT-REG
           STRING 'EBACCR01 ACCRUAL OK - DATA '
                  WS-DATA-SISTEMA
                  ' HORA '
                  WS-HORA-SISTEMA
                  ' CONTAS='
                  WS-CT-PROCESSADAS
                  ' MOV='
                  WS-CT-MOV-GERADOS
                  DELIMITED BY SIZE INTO AUDIT-REG
           END-STRING
           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** ERRO WRITE AUDIT - STATUS: '
                       WS-FS-AUDIT
           END-IF.

      *---------------------------------------------------------------*
      * Fecha arquivos com verificacao de FILE STATUS                 *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF PARM-ABERTO
               CLOSE PARM-IN
               IF NOT FS-PARM-OK
                   DISPLAY '*** ERRO CLOSE PARM-IN - STATUS: '
                           WS-FS-PARM
               END-IF
           END-IF

           IF CONTA-ABERTO
               CLOSE CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** ERRO CLOSE CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF ACCR-ABERTO
               CLOSE ACCR-OUT
               IF NOT FS-ACCR-OK
                   DISPLAY '*** ERRO CLOSE ACCR-OUT - STATUS: '
                           WS-FS-ACCR
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF LANCTO-ABERTO
               CLOSE LANCTO-ESDS
               IF NOT FS-LANCTO-OK
                   DISPLAY '*** ERRO CLOSE LANCTO-ESDS - STATUS: '
                           WS-FS-LANCTO
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF AUDIT-ABERTO
               CLOSE AUDIT-OUT
               IF NOT FS-AUDIT-OK
                   DISPLAY '*** ERRO CLOSE AUDIT-OUT - STATUS: '
                           WS-FS-AUDIT
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo e define RETURN-CODE                             *
      *---------------------------------------------------------------*
       9100-DEFINIR-RETURN-CODE.
           DISPLAY '*** RESUMO ACCRUAL ***'
           DISPLAY 'CONTAS LIDAS       : ' WS-CT-LIDAS
           DISPLAY 'CONTAS PROCESSADAS : ' WS-CT-PROCESSADAS
           DISPLAY 'CONTAS IGNORADAS   : ' WS-CT-IGNORADAS
           DISPLAY 'MOVIMENTOS GERADOS : ' WS-CT-MOV-GERADOS
           DISPLAY 'TOTAL JUROS        : ' WS-TOTAL-JUROS
           DISPLAY 'TOTAL TARIFAS      : ' WS-TOTAL-TARIFAS

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-CT-PROCESSADAS = ZERO
                   DISPLAY '*** ATENCAO: NENHUMA CONTA ATIVA PROCESSADA'
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
