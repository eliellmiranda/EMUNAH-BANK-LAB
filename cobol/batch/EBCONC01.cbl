       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCONC01.
      *===============================================================*
      * PROGRAMA : EBCONC01                                           *
      * FUNCAO   : CONCILIACAO TRES-VIAS DO CICLO DIARIO              *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * Verifica 3 equacoes ao fim do processamento diario e grava    *
      * o resultado estruturado em CONCIL.SEQ (lido pelo EBJEOD01):   *
      *                                                               *
      * CHECK1 - CONTAGEM (bloqueante RC=8):                          *
      *   COUNT(ENTRIN) = COUNT(MOVTIN) + COUNT(REJEIT)               *
      *   Garante que nenhum registro de entrada se perdeu.           *
      *                                                               *
      * CHECK2 - LIQUIDEZ (informativo):                              *
      *   NET = SUM_CREDITOS(MOVTIN) - SUM_DEBITOS(MOVTIN)            *
      *   Mostra o liquido financeiro do dia.                         *
      *                                                               *
      * CHECK3 - SALDO (alerta RC=4 se falhar):                       *
      *   SUM(SALDOIN) = SUM(CONTA.CNT-SALDO)                         *
      *   Confirma que o snapshot GDG bate com o KSDS de contas.      *
      *   Se SALDOIN nao estiver disponivel (primeiro ciclo ou GDG    *
      *   nao criado), o check e ignorado sem bloquear.               *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Todos os checks passaram                        *
      *   RC = 4  --> Divergencia de saldo (alerta)                   *
      *   RC = 8  --> Divergencia de contagem ou erro de I/O          *
      *                                                               *
      * OBS: EBJCONC.jcl deve ter os DDs: ENTRIN, MOVTIN, REJEIT,     *
      *      SALDOIN (opcional), CONTA, CONCOUT.                      *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * ENTRIN = arquivo de entrada original do dia (ENTRADA.SEQ)     *
      *---------------------------------------------------------------*
           SELECT ENTRIN-IN
               ASSIGN TO ENTRIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ENTRIN.

      *---------------------------------------------------------------*
      * MOVTIN = lancamentos validos postados (LANCTO.ESDS)           *
      *---------------------------------------------------------------*
           SELECT MOVTO-IN
               ASSIGN TO MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * REJEIT = rejeitos do dia (REJEITOS.SEQ)                       *
      *---------------------------------------------------------------*
           SELECT REJEIT-IN
               ASSIGN TO REJEIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJEIT.

      *---------------------------------------------------------------*
      * SALDOIN = snapshot GDG do dia (ARQ.SALDO.GDG(0)) - opcional   *
      *---------------------------------------------------------------*
           SELECT SALDO-IN
               ASSIGN TO SALDOIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-SALDO.

      *---------------------------------------------------------------*
      * CONTA = KSDS master de contas (para somar saldo atual)        *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * CONCOUT = saida da conciliacao (ARQ.CONCIL.SEQ)               *
      *---------------------------------------------------------------*
           SELECT CONCIL-OUT
               ASSIGN TO CONCOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONCOUT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de entrada original (120 bytes)                       *
      *---------------------------------------------------------------*
       FD  ENTRIN-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ENTRIN-REG                 PIC X(120).

      *---------------------------------------------------------------*
      * Arquivo de lancamentos validos (120 bytes)                    *
      * Layout: AG(4)+CTA(8)+DT(8)+TIPO(1)+VALOR(13)+HIST(30)+...    *
      *---------------------------------------------------------------*
       FD  MOVTO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  MOVTO-IN-REG.
           05 MV-AGENCIA              PIC X(4).
           05 MV-CONTA                PIC X(8).
           05 MV-DATA                 PIC X(8).
           05 MV-TIPO                 PIC X(1).
           05 MV-VALOR                PIC 9(11)V99.
           05 FILLER                  PIC X(86).

      *---------------------------------------------------------------*
      * Arquivo de rejeitos (120 bytes)                               *
      *---------------------------------------------------------------*
       FD  REJEIT-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-REG                 PIC X(120).

      *---------------------------------------------------------------*
      * Snapshot de saldo GDG (120 bytes)                             *
      * Layout gerado pelo EBSNAP01:                                   *
      *   SLD-AGENCIA(4) SLD-CONTA(8) SLD-SALDO S9(11)V99(13)        *
      *   SLD-DATA(8) FILLER(87)                                      *
      *---------------------------------------------------------------*
       FD  SALDO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  SALDO-IN-REG.
           05 SLD-AGENCIA             PIC X(4).
           05 SLD-CONTA               PIC X(8).
           05 SLD-SALDO               PIC S9(11)V99.
           05 SLD-DATA                PIC X(8).
           05 FILLER                  PIC X(87).

      *---------------------------------------------------------------*
      * KSDS master de contas                                         *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de saida da conciliacao (120 bytes)                   *
      *---------------------------------------------------------------*
       FD  CONCIL-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  CONCIL-REG                 PIC X(120).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status                                                   *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-ENTRIN            PIC XX VALUE SPACES.
              88 FS-ENTRIN-OK         VALUE '00'.
              88 FS-ENTRIN-EOF        VALUE '10'.
           05 WS-FS-MOVTIN            PIC XX VALUE SPACES.
              88 FS-MOVTIN-OK         VALUE '00'.
              88 FS-MOVTIN-EOF        VALUE '10'.
           05 WS-FS-REJEIT            PIC XX VALUE SPACES.
              88 FS-REJEIT-OK         VALUE '00'.
              88 FS-REJEIT-EOF        VALUE '10'.
           05 WS-FS-SALDO             PIC XX VALUE SPACES.
              88 FS-SALDO-OK          VALUE '00'.
              88 FS-SALDO-EOF         VALUE '10'.
           05 WS-FS-CONTA             PIC XX VALUE SPACES.
              88 FS-CONTA-OK          VALUE '00'.
              88 FS-CONTA-EOF         VALUE '10'.
           05 WS-FS-CONCOUT           PIC XX VALUE SPACES.
              88 FS-CONCOUT-OK        VALUE '00'.

      *---------------------------------------------------------------*
      * Controles de EOF                                              *
      *---------------------------------------------------------------*
       01  WS-EOF.
           05 WS-EOF-ENTRIN           PIC X VALUE 'N'.
              88 EOF-ENTRIN           VALUE 'S'.
           05 WS-EOF-MOVTIN           PIC X VALUE 'N'.
              88 EOF-MOVTIN           VALUE 'S'.
           05 WS-EOF-REJEIT           PIC X VALUE 'N'.
              88 EOF-REJEIT           VALUE 'S'.
           05 WS-EOF-SALDO            PIC X VALUE 'N'.
              88 EOF-SALDO            VALUE 'S'.
           05 WS-EOF-CONTA            PIC X VALUE 'N'.
              88 EOF-CONTA            VALUE 'S'.

      *---------------------------------------------------------------*
      * Flags de controle                                             *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.
           05 WS-SALDO-DISP           PIC X VALUE 'N'.
              88 SALDO-DISPONIVEL     VALUE 'S'.
              88 SALDO-INDISPONIVEL   VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ABERTOS.
           05 WS-ENTRIN-ABERTO        PIC X VALUE 'N'.
              88 ENTRIN-ABERTO        VALUE 'S'.
           05 WS-MOVTIN-ABERTO        PIC X VALUE 'N'.
              88 MOVTIN-ABERTO        VALUE 'S'.
           05 WS-REJEIT-ABERTO        PIC X VALUE 'N'.
              88 REJEIT-ABERTO        VALUE 'S'.
           05 WS-SALDO-ABERTO         PIC X VALUE 'N'.
              88 SALDO-ABERTO         VALUE 'S'.
           05 WS-CONTA-ABERTO         PIC X VALUE 'N'.
              88 CONTA-ABERTO         VALUE 'S'.
           05 WS-CONCOUT-ABERTO       PIC X VALUE 'N'.
              88 CONCOUT-ABERTO       VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores                                                    *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CT-ENTRIN            PIC 9(9) VALUE ZERO.
           05 WS-CT-MOVTIN            PIC 9(9) VALUE ZERO.
           05 WS-CT-REJEIT            PIC 9(9) VALUE ZERO.
           05 WS-CT-CONTA             PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Acumuladores financeiros                                      *
      *---------------------------------------------------------------*
       01  WS-ACUMULADORES.
           05 WS-SOMA-CREDITOS        PIC S9(15)V99 VALUE ZERO.
           05 WS-SOMA-DEBITOS         PIC S9(15)V99 VALUE ZERO.
           05 WS-MOV-LIQUIDO          PIC S9(15)V99 VALUE ZERO.
           05 WS-SOMA-SALDO-GDG       PIC S9(15)V99 VALUE ZERO.
           05 WS-SOMA-SALDO-CONTA     PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Resultados dos checks                                         *
      *---------------------------------------------------------------*
       01  WS-CHECKS.
           05 WS-CHECK1-OK            PIC X VALUE 'N'.
              88 CHECK1-PASSOU        VALUE 'S'.
              88 CHECK1-DIVERGENCIA   VALUE 'N'.
           05 WS-CHECK3-OK            PIC X VALUE 'N'.
              88 CHECK3-PASSOU        VALUE 'S'.
              88 CHECK3-DIVERGENCIA   VALUE 'N'.

      *---------------------------------------------------------------*
      * Data e hora do sistema                                        *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA            PIC 9(8).
       01  WS-HORA-SISTEMA            PIC 9(8).

      *---------------------------------------------------------------*
      * Area de trabalho para montar linhas de saida                  *
      *---------------------------------------------------------------*
       01  WS-OUT-LINE                PIC X(120).

      *---------------------------------------------------------------*
      * Campos de edicao                                              *
      *---------------------------------------------------------------*
       01  WS-EDICAO.
           05 WS-EDIT-CT              PIC ZZZ.ZZZ.ZZ9.
           05 WS-EDIT-VAL             PIC -ZZZ.ZZZ.ZZZ.ZZZ.ZZ9,99.

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME

           PERFORM 1000-ABRIR-ARQUIVOS

           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-CONTAR-ENTRIN
               PERFORM 2100-CONTAR-E-SOMAR-MOVTIN
               PERFORM 2200-CONTAR-REJEIT
               PERFORM 2300-SOMAR-SALDO-GDG
               PERFORM 2400-SOMAR-CONTA-KSDS
               PERFORM 3000-EXECUTAR-CHECKS
               PERFORM 4000-GERAR-CONCIL
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Abre arquivos. SALDOIN e opcional: OPEN com falha nao bloqueia*
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT ENTRIN-IN
           IF FS-ENTRIN-OK
               SET ENTRIN-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN ENTRIN - STATUS: '
                       WS-FS-ENTRIN
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN INPUT MOVTO-IN
               IF FS-MOVTIN-OK
                   SET MOVTIN-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN MOVTIN - STATUS: '
                           WS-FS-MOVTIN
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN INPUT REJEIT-IN
               IF FS-REJEIT-OK
                   SET REJEIT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN REJEIT - STATUS: '
                           WS-FS-REJEIT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN INPUT CONTA-KSDS
               IF FS-CONTA-OK
                   SET CONTA-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               OPEN OUTPUT CONCIL-OUT
               IF FS-CONCOUT-OK
                   SET CONCOUT-ABERTO TO TRUE
               ELSE
                   DISPLAY '*** ERRO OPEN CONCOUT - STATUS: '
                           WS-FS-CONCOUT
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

      *    SALDOIN opcional: falha de OPEN nao bloqueia o processamento
           IF NAO-OCORREU-ERRO-IO
               OPEN INPUT SALDO-IN
               IF FS-SALDO-OK
                   SET SALDO-ABERTO     TO TRUE
                   SET SALDO-DISPONIVEL TO TRUE
               ELSE
                   DISPLAY '*** AVISO: SALDOIN indisponivel - '
                           'CHECK3 ignorado. STATUS: '
                           WS-FS-SALDO
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Conta registros do arquivo de entrada original                *
      *---------------------------------------------------------------*
       2000-CONTAR-ENTRIN.
           PERFORM UNTIL EOF-ENTRIN OR OCORREU-ERRO-IO
               READ ENTRIN-IN
                   AT END
                       SET EOF-ENTRIN TO TRUE
                   NOT AT END
                       IF FS-ENTRIN-OK
                           ADD 1 TO WS-CT-ENTRIN
                       ELSE
                           DISPLAY '*** ERRO READ ENTRIN - STATUS: '
                                   WS-FS-ENTRIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Conta lancamentos validos e acumula creditos / debitos        *
      *---------------------------------------------------------------*
       2100-CONTAR-E-SOMAR-MOVTIN.
           PERFORM UNTIL EOF-MOVTIN OR OCORREU-ERRO-IO
               READ MOVTO-IN
                   AT END
                       SET EOF-MOVTIN TO TRUE
                   NOT AT END
                       IF FS-MOVTIN-OK
                           ADD 1 TO WS-CT-MOVTIN
                           EVALUATE MV-TIPO
                               WHEN 'C'
                                   ADD MV-VALOR TO WS-SOMA-CREDITOS
                               WHEN 'D'
                                   ADD MV-VALOR TO WS-SOMA-DEBITOS
                           END-EVALUATE
                       ELSE
                           DISPLAY '*** ERRO READ MOVTIN - STATUS: '
                                   WS-FS-MOVTIN
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM
           COMPUTE WS-MOV-LIQUIDO =
               WS-SOMA-CREDITOS - WS-SOMA-DEBITOS.

      *---------------------------------------------------------------*
      * Conta registros de rejeitos                                   *
      *---------------------------------------------------------------*
       2200-CONTAR-REJEIT.
           PERFORM UNTIL EOF-REJEIT OR OCORREU-ERRO-IO
               READ REJEIT-IN
                   AT END
                       SET EOF-REJEIT TO TRUE
                   NOT AT END
                       IF FS-REJEIT-OK
                           ADD 1 TO WS-CT-REJEIT
                       ELSE
                           DISPLAY '*** ERRO READ REJEIT - STATUS: '
                                   WS-FS-REJEIT
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Soma saldo do snapshot GDG (se disponivel)                    *
      *---------------------------------------------------------------*
       2300-SOMAR-SALDO-GDG.
           IF SALDO-INDISPONIVEL
               EXIT
           END-IF

           PERFORM UNTIL EOF-SALDO OR OCORREU-ERRO-IO
               READ SALDO-IN
                   AT END
                       SET EOF-SALDO TO TRUE
                   NOT AT END
                       IF FS-SALDO-OK
                           ADD SLD-SALDO TO WS-SOMA-SALDO-GDG
                       ELSE
                           DISPLAY '*** ERRO READ SALDOIN - STATUS: '
                                   WS-FS-SALDO
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Soma saldo atual do KSDS de contas                            *
      *---------------------------------------------------------------*
       2400-SOMAR-CONTA-KSDS.
           PERFORM UNTIL EOF-CONTA OR OCORREU-ERRO-IO
               READ CONTA-KSDS NEXT
                   AT END
                       SET EOF-CONTA TO TRUE
                   NOT AT END
                       IF FS-CONTA-OK
                           ADD 1 TO WS-CT-CONTA
                           ADD CNT-SALDO OF CONTA-REG
                               TO WS-SOMA-SALDO-CONTA
                       ELSE
                           DISPLAY '*** ERRO READ CONTA-KSDS - '
                                   WS-FS-CONTA
                           SET OCORREU-ERRO-IO TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Executa os checks de conciliacao                              *
      *---------------------------------------------------------------*
       3000-EXECUTAR-CHECKS.
      *    Check 1: contagem global
           IF WS-CT-ENTRIN = WS-CT-MOVTIN + WS-CT-REJEIT
               SET CHECK1-PASSOU TO TRUE
           END-IF

      *    Check 3: saldo GDG bate com KSDS (ignorado se sem SALDOIN)
           IF SALDO-INDISPONIVEL
               SET CHECK3-PASSOU TO TRUE
           ELSE
               IF WS-SOMA-SALDO-GDG = WS-SOMA-SALDO-CONTA
                   SET CHECK3-PASSOU TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Gera o arquivo de conciliacao com resultado de cada check     *
      *---------------------------------------------------------------*
       4000-GERAR-CONCIL.
      *    Cabecalho
           MOVE SPACES TO WS-OUT-LINE
           STRING 'CONCILIACAO EMUNAH BANK  DATA: '
                  WS-DATA-SISTEMA
                  '  HORA: '
                  WS-HORA-SISTEMA
                  DELIMITED BY SIZE INTO WS-OUT-LINE
           END-STRING
           MOVE WS-OUT-LINE TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL

           MOVE ALL '-' TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL

      *    Check 1 - Contagem
           MOVE WS-CT-ENTRIN  TO WS-EDIT-CT
           MOVE SPACES TO WS-OUT-LINE
           STRING 'CHECK1-CONTAGEM  ENTRADA='
                  WS-EDIT-CT
                  DELIMITED BY SIZE INTO WS-OUT-LINE
           END-STRING
           MOVE WS-CT-MOVTIN TO WS-EDIT-CT
           STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                  '  VALIDOS='
                  WS-EDIT-CT
                  DELIMITED BY SIZE INTO WS-OUT-LINE
           END-STRING
           MOVE WS-CT-REJEIT TO WS-EDIT-CT
           STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                  '  REJEITOS='
                  WS-EDIT-CT
                  DELIMITED BY SIZE INTO WS-OUT-LINE
           END-STRING
           IF CHECK1-PASSOU
               STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                      '  [PASSOU]'
                      DELIMITED BY SIZE INTO WS-OUT-LINE
               END-STRING
           ELSE
               STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                      '  [DIVERGENCIA]'
                      DELIMITED BY SIZE INTO WS-OUT-LINE
               END-STRING
           END-IF
           MOVE WS-OUT-LINE TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL

      *    Check 2 - Movimento liquido (informativo)
           MOVE WS-MOV-LIQUIDO TO WS-EDIT-VAL
           MOVE SPACES TO WS-OUT-LINE
           STRING 'CHECK2-LIQUIDEZ  CREDITOS-DEBITOS='
                  WS-EDIT-VAL
                  '  [INFORMATIVO]'
                  DELIMITED BY SIZE INTO WS-OUT-LINE
           END-STRING
           MOVE WS-OUT-LINE TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL

      *    Check 3 - Saldo GDG vs KSDS
           MOVE SPACES TO WS-OUT-LINE
           IF SALDO-DISPONIVEL
               MOVE WS-SOMA-SALDO-GDG TO WS-EDIT-VAL
               STRING 'CHECK3-SALDO     GDG='
                      WS-EDIT-VAL
                      DELIMITED BY SIZE INTO WS-OUT-LINE
               END-STRING
               MOVE WS-SOMA-SALDO-CONTA TO WS-EDIT-VAL
               STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                      '  CONTA='
                      WS-EDIT-VAL
                      DELIMITED BY SIZE INTO WS-OUT-LINE
               END-STRING
               IF CHECK3-PASSOU
                   STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                          '  [PASSOU]'
                          DELIMITED BY SIZE INTO WS-OUT-LINE
                   END-STRING
               ELSE
                   STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                          '  [DIVERGENCIA]'
                          DELIMITED BY SIZE INTO WS-OUT-LINE
                   END-STRING
               END-IF
           ELSE
               MOVE 'CHECK3-SALDO     [IGNORADO - SALDOIN AUSENTE]'
                   TO WS-OUT-LINE
           END-IF
           MOVE WS-OUT-LINE TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL

      *    Status final
           MOVE ALL '-' TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL

           MOVE SPACES TO WS-OUT-LINE
           EVALUATE TRUE
               WHEN CHECK1-DIVERGENCIA
                   MOVE 'STATUS: [DIVERGENCIA] CONTAGEM - '
                       TO WS-OUT-LINE
                   STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                          'ENTRADA <> VALIDOS + REJEITOS'
                          DELIMITED BY SIZE INTO WS-OUT-LINE
                   END-STRING
               WHEN CHECK3-DIVERGENCIA
                   MOVE 'STATUS: [DIVERGENCIA] SALDO - '
                       TO WS-OUT-LINE
                   STRING FUNCTION TRIM(WS-OUT-LINE TRAILING)
                          'VERIFICAR EBJSNAP E EBPOST01'
                          DELIMITED BY SIZE INTO WS-OUT-LINE
                   END-STRING
               WHEN OTHER
                   MOVE 'STATUS: [PASSOU] DIA APTO PARA EOD'
                       TO WS-OUT-LINE
           END-EVALUATE
           MOVE WS-OUT-LINE TO CONCIL-REG
           PERFORM 4900-ESCREVER-CONCIL.

      *---------------------------------------------------------------*
      * Grava linha no CONCIL.SEQ                                     *
      *---------------------------------------------------------------*
       4900-ESCREVER-CONCIL.
           WRITE CONCIL-REG
           IF NOT FS-CONCOUT-OK
               DISPLAY '*** ERRO WRITE CONCIL-OUT - STATUS: '
                       WS-FS-CONCOUT
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Fecha arquivos com verificacao de FILE STATUS                 *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF ENTRIN-ABERTO
               CLOSE ENTRIN-IN
               IF NOT FS-ENTRIN-OK
                   DISPLAY '*** ERRO CLOSE ENTRIN - STATUS: '
                           WS-FS-ENTRIN
               END-IF
           END-IF

           IF MOVTIN-ABERTO
               CLOSE MOVTO-IN
               IF NOT FS-MOVTIN-OK
                   DISPLAY '*** ERRO CLOSE MOVTIN - STATUS: '
                           WS-FS-MOVTIN
               END-IF
           END-IF

           IF REJEIT-ABERTO
               CLOSE REJEIT-IN
               IF NOT FS-REJEIT-OK
                   DISPLAY '*** ERRO CLOSE REJEIT - STATUS: '
                           WS-FS-REJEIT
               END-IF
           END-IF

           IF SALDO-ABERTO
               CLOSE SALDO-IN
               IF NOT FS-SALDO-OK
                   DISPLAY '*** ERRO CLOSE SALDOIN - STATUS: '
                           WS-FS-SALDO
               END-IF
           END-IF

           IF CONTA-ABERTO
               CLOSE CONTA-KSDS
               IF NOT FS-CONTA-OK
                   DISPLAY '*** ERRO CLOSE CONTA-KSDS - STATUS: '
                           WS-FS-CONTA
               END-IF
           END-IF

           IF CONCOUT-ABERTO
               CLOSE CONCIL-OUT
               IF NOT FS-CONCOUT-OK
                   DISPLAY '*** ERRO CLOSE CONCOUT - STATUS: '
                           WS-FS-CONCOUT
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo no SYSOUT e define RETURN-CODE                   *
      *---------------------------------------------------------------*
       9100-DEFINIR-RETURN-CODE.
           DISPLAY '*** RESUMO CONCILIACAO TRES-VIAS ***'
           DISPLAY 'ENTRADA LIDA      : ' WS-CT-ENTRIN
           DISPLAY 'VALIDOS           : ' WS-CT-MOVTIN
           DISPLAY 'REJEITOS          : ' WS-CT-REJEIT
           DISPLAY 'CONTAS NO KSDS    : ' WS-CT-CONTA
           DISPLAY 'CREDITOS          : ' WS-SOMA-CREDITOS
           DISPLAY 'DEBITOS           : ' WS-SOMA-DEBITOS
           DISPLAY 'MOVIMENTO LIQUIDO : ' WS-MOV-LIQUIDO
           IF SALDO-DISPONIVEL
               DISPLAY 'SALDO GDG TOTAL   : ' WS-SOMA-SALDO-GDG
               DISPLAY 'SALDO CONTA TOTAL : ' WS-SOMA-SALDO-CONTA
           END-IF

           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN CHECK1-DIVERGENCIA
                   MOVE 8 TO RETURN-CODE
               WHEN CHECK3-DIVERGENCIA
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.