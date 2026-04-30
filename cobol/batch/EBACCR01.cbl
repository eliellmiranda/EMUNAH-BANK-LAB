      *===============================================================*
      * PROGRAMA : EBACCR01                                           *
      * FUNCAO   : ACCRUALS DIARIOS DE JUROS E TARIFAS                *
      * MODULO   : ACCR (Accrual)                                     *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le PARM.JUROS.CONFIG e carrega taxas de juros e tarifas     *
      * - Percorre o KSDS de contas sequencialmente                   *
      * - Para contas ATIVAS calcula juros e/ou tarifa conforme tipo  *
      * - Atualiza CNT-SALDO via REWRITE no KSDS                      *
      * - Grava cada movimento em ACCR.MOV.SEQ (saida exclusiva)      *
      * - Apenda o mesmo movimento em ARQ.LANCTO.ESDS (historico)     *
      * - Registra resumo de execucao na trilha de auditoria          *
      *                                                               *
      * QUANDO EXECUTAR:                                              *
      * - Entre EOTI e snapshot (EBSNAP01) no ciclo do dia            *
      * - Apos todas as postagens do EBPOST01                         *
      * - Os movimentos gerados impactam o snapshot e a conciliacao   *
      *                                                               *
      * ENTRADAS:                                                     *
      *   PARMLIB  = Z77948.EMUNAH.PARMLIB(JUROS)  (config de taxas)  *
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS  (master contas)    *
      *                                                               *
      * SAIDAS:                                                       *
      *   ACCROUT  = Z77948.EMUNAH.ARQ.ACCR.MOV.SEQ (mov do accrual)  *
      *   LANCTO   = Z77948.EMUNAH.ARQ.LANCTO.ESDS  (historico)       *
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ    (trilha)          *
      *                                                               *
      * LAYOUT DO PARM.JUROS.CONFIG (LRECL=80):                       *
      *   POS 1    : tipo  J=juros  T=tarifa  *=comentario (ignorado) *
      *   POS 2    : tipo de conta  C=corrente  P=poupanca            *
      *   POS 3-7  : valor PIC 9(3)V99  ex: 00050 = 0.50% / R$0,50   *
      *   POS 8-80 : FILLER / descricao livre                         *
      *                                                               *
      * EXEMPLO DE CONFIGURACAO:                                       *
      *   JC00000  JUROS CORRENTE - ISENTO                            *
      *   JP00050  JUROS POUPANCA - 0.50% AO MES                      *
      *   TC01250  TARIFA CORRENTE - R$ 12.50 AO MES                  *
      *   TP00000  TARIFA POUPANCA - ISENTA                           *
      *                                                               *
      * REGRAS DE CALCULO:                                            *
      *   Juros: aplicados somente se saldo > 0 e taxa > 0            *
      *   Tarifa: aplicada se tarifa > 0 (independe do saldo)         *
      *   Contas INATIVAS e BLOQUEADAS sao ignoradas sem erro         *
      *   Tipo desconhecido (nao C nem P): ignorado sem erro           *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPCNT001 = layout de conta (100 bytes)                      *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Accrual executado com sucesso                   *
      *   RC = 4  --> Nenhuma conta ativa processada (KSDS vazio)     *
      *   RC = 8  --> Erro critico de I/O ou PARM invalido            *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBACCR01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * PARM-IN: arquivo de parametros com taxas e tarifas            *
      * Linhas com * na pos 1 sao comentarios e ignoradas             *
      * DDNAME: PARMLIB   LRECL: 80   RECFM: FB                       *
      *---------------------------------------------------------------*
           SELECT PARM-IN
               ASSIGN TO PARMLIB
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-PARM.

      *---------------------------------------------------------------*
      * CONTA-KSDS: percorrido sequencialmente via READ NEXT           *
      * Aberto em I-O para permitir REWRITE apos calculo              *
      * DDNAME: CONTA                                                 *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * ACCR-OUT: movimentos de accrual exclusivos desta execucao     *
      * Aberto em OUTPUT — sobrescrito a cada execucao diaria         *
      * DDNAME: ACCROUT   LRECL: 120   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT ACCR-OUT
               ASSIGN TO ACCROUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ACCR.

      *---------------------------------------------------------------*
      * LANCTO-ESDS: historico de lancamentos — accrual e apendado    *
      * DISP=MOD no JCL para preservar lancamentos anteriores         *
      * DDNAME: LANCTO   LRECL: 120                                   *
      *---------------------------------------------------------------*
           SELECT LANCTO-ESDS
               ASSIGN TO AS-LANCTO
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-LANCTO.

      *---------------------------------------------------------------*
      * AUDIT-OUT: trilha de auditoria com resumo do accrual          *
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
      * Arquivo de parametros (80 bytes)                              *
      * Campos interpretados pelo 2100-INTERPRETAR-PARM               *
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
      * KSDS de contas — layout via CPCNT001                          *
      * Percorrido via READ NEXT e atualizado via REWRITE              *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Movimentos de accrual (120 bytes)                             *
      * Layout compativel com LANCTO.ESDS para gravacao dupla         *
      * C = credito de juros   D = debito de tarifa                   *
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
      * ESDS de lancamentos — recebe copia do ACCR-REG via MOVE       *
      * Permite que o accrual apareca no extrato e na conciliacao     *
      *---------------------------------------------------------------*
       FD  LANCTO-ESDS
           RECORD CONTAINS 120 CHARACTERS.           
       01  LANCTO-REG                 PIC X(120).

      *---------------------------------------------------------------*
      * Auditoria (120 bytes) — texto livre via STRING                *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      * '00' = OK   '10' = EOF                                        *
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
      * Flags de controle de EOF e estado                             *
      * PARM-CARREGADO: impede processamento se PARM nao foi lido     *
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
      * Controle de arquivos abertos para CLOSE seguro                *
      * Cada flag e setado para 'S' apos OPEN bem-sucedido            *
      * Permite fechar apenas o que foi aberto, evitando abend        *
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
      * Taxas e tarifas carregadas do PARM.JUROS.CONFIG               *
      * Zeradas por default — sem configuracao = sem accrual          *
      *---------------------------------------------------------------*
       01  WS-PARAMETROS.
           05 WS-TAXA-JUROS-CORRENTE  PIC 9(3)V99 VALUE ZERO.
           05 WS-TAXA-JUROS-POUPANCA  PIC 9(3)V99 VALUE ZERO.
           05 WS-TARIFA-CORRENTE      PIC 9(3)V99 VALUE ZERO.
           05 WS-TARIFA-POUPANCA      PIC 9(3)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Valores calculados para a conta em processamento              *
      * Reinicializados a zero para cada nova conta                   *
      *---------------------------------------------------------------*
       01  WS-CALC.
           05 WS-JUROS-VALOR          PIC S9(11)V99 VALUE ZERO.
           05 WS-TARIFA-VALOR         PIC S9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Contadores para o resumo final                                *
      * CT-IGNORADAS: contas inativas, bloqueadas ou tipo desconhecido*
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CT-LIDAS             PIC 9(9) VALUE ZERO.
           05 WS-CT-PROCESSADAS       PIC 9(9) VALUE ZERO.
           05 WS-CT-IGNORADAS         PIC 9(9) VALUE ZERO.
           05 WS-CT-MOV-GERADOS       PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Totalizadores financeiros exibidos no SYSOUT                  *
      *---------------------------------------------------------------*
       01  WS-TOTAIS.
           05 WS-TOTAL-JUROS          PIC S9(15)V99 VALUE ZERO.
           05 WS-TOTAL-TARIFAS        PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora capturadas no inicio do programa                  *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA            PIC 9(8).
       01  WS-HORA-SISTEMA            PIC 9(8).

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Fluxo: abre arquivos -> carrega PARM -> processa contas ->    *
      * audita -> fecha -> define RC                                  *
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
      * 1000-ABRIR-ARQUIVOS                                           *
      * Cada arquivo e aberto condicionalmente ao sucesso do anterior *
      * CONTA-KSDS em I-O para REWRITE                               *
      * ACCR-OUT em OUTPUT (nova saida diaria)                        *
      * LANCTO-ESDS e AUDIT em EXTEND (acumulam sem sobrescrever)     *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT PARM-IN
           IF FS-PARM-OK
               SET PARM-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN PARM-IN - STATUS: ' WS-FS-PARM
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
      * 2000-CARREGAR-PARAMETROS                                      *
      * Le o PARM linha a linha e carrega as 4 variaveis de taxa      *
      * Linhas com PARM-TIPO = '*' sao comentarios e ignoradas        *
      * Exibe as taxas carregadas no SYSOUT para conferencia          *
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
      * 2100-INTERPRETAR-PARM                                         *
      * Mapeia cada linha do PARM para a variavel correta             *
      * Combinacao J+C, J+P, T+C, T+P — demais sao avisadas          *
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
      * 3000-PROCESSAR-CONTAS                                         *
      * Percorre o KSDS via READ NEXT                                 *
      * Contas ATIVAS (status A) passam pelo calculo                  *
      * Contas INATIVAS ou BLOQUEADAS sao ignoradas sem erro          *
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
      * 3100-CALCULAR-E-APLICAR                                       *
      * Calcula juros e tarifa conforme tipo da conta                 *
      * Aplica ao saldo e persiste via REWRITE                        *
      * Aciona gravacao dos movimentos se houver valor a registrar    *
      *---------------------------------------------------------------*
       3100-CALCULAR-E-APLICAR.
           MOVE ZERO TO WS-JUROS-VALOR WS-TARIFA-VALOR

      *    Calcula conforme tipo — somente conta C ou P tem accrual
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
      *            Tipo desconhecido (ex: S=Salario): ignora sem erro
                   ADD 1 TO WS-CT-IGNORADAS
                   EXIT PARAGRAPH
           END-EVALUATE

      *    Aplica juros (credito) e tarifa (debito) no saldo
           IF WS-JUROS-VALOR > ZERO
               ADD WS-JUROS-VALOR TO CNT-SALDO OF CONTA-REG
           END-IF
           IF WS-TARIFA-VALOR > ZERO
               SUBTRACT WS-TARIFA-VALOR FROM CNT-SALDO OF CONTA-REG
           END-IF

      *    Persiste saldo atualizado no KSDS
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

      *    Grava movimento de juros se calculado
           IF WS-JUROS-VALOR > ZERO
               PERFORM 3200-GRAVAR-MOVIMENTO-JUROS
           END-IF

      *    Grava movimento de tarifa se aplicada
           IF WS-TARIFA-VALOR > ZERO
               PERFORM 3300-GRAVAR-MOVIMENTO-TARIFA
           END-IF.

      *---------------------------------------------------------------*
      * 3200-GRAVAR-MOVIMENTO-JUROS                                   *
      * Monta registro de credito de juros e aciona gravacao dupla    *
      * Canal = BATCH-ACCR para identificacao no extrato              *
      *---------------------------------------------------------------*
       3200-GRAVAR-MOVIMENTO-JUROS.
           MOVE SPACES            TO ACCR-REG
           MOVE CNT-AGENCIA   OF CONTA-REG TO ACR-AGENCIA
           MOVE CNT-NUM-CONTA OF CONTA-REG TO ACR-NUM-CONTA
           MOVE WS-DATA-SISTEMA            TO ACR-DATA
           MOVE 'C'                        TO ACR-TIPO
           MOVE WS-JUROS-VALOR             TO ACR-VALOR
           MOVE 'ACCRUAL JUROS MENSAIS'    TO ACR-HISTORICO
           MOVE 'BATCH-ACCR'               TO ACR-CANAL
           PERFORM 3900-GRAVAR-NOS-DOIS-DESTINOS
           ADD WS-JUROS-VALOR TO WS-TOTAL-JUROS.

      *---------------------------------------------------------------*
      * 3300-GRAVAR-MOVIMENTO-TARIFA                                  *
      * Monta registro de debito de tarifa e aciona gravacao dupla    *
      *---------------------------------------------------------------*
       3300-GRAVAR-MOVIMENTO-TARIFA.
           MOVE SPACES            TO ACCR-REG
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
      * 3900-GRAVAR-NOS-DOIS-DESTINOS                                 *
      * Grava ACCR-REG em ACCR-OUT e uma copia em LANCTO-ESDS         *
      * Centraliza o tratamento de erro de ambos os WRITEs            *
      * O MOVE de ACCR-REG para LANCTO-REG funciona pois ambos        *
      * tem 120 bytes e layout compativel                             *
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
      * 4000-GRAVAR-AUDITORIA                                         *
      * Grava registro de auditoria com resumo do accrual             *
      * Texto livre montado via STRING com contadores e totais        *
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
               DISPLAY '*** ERRO WRITE AUDIT - STATUS: ' WS-FS-AUDIT
           END-IF.

      *---------------------------------------------------------------*
      * 9000-FECHAR-ARQUIVOS                                          *
      * Fecha apenas os arquivos que foram abertos com sucesso        *
      * Verifica FILE STATUS apos cada CLOSE                          *
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
      * 9100-DEFINIR-RETURN-CODE                                      *
      * Exibe resumo completo no SYSOUT                               *
      * RC=0: accrual executado com sucesso                           *
      * RC=4: nenhuma conta ativa processada                          *
      * RC=8: erro critico de I/O ou PARM invalido                    *
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