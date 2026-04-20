       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCTL01.
      *===============================================================*
      * PROGRAMA : EBCTL01                                            *
      * FUNCAO   : UTILITARIO DE CONTROLE DE STATUS DO BRANCH         *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe o STATUS DESTINO via PARM do JCL                     *
      * - Le o status atual de ARQ.CTL.STATUS                         *
      * - Valida se a transicao solicitada e permitida                *
      * - Se valida: grava o novo status e RC=0                       *
      * - Se invalida: exibe erro e RC=8                              *
      *                                                               *
      * TRANSICOES VALIDAS:                                           *
      *   (vazio)  --> OPEN    (inicio do dia / primeiro uso)         *
      *   CLOSED   --> OPEN    (reabertura do dia seguinte)           *
      *   OPEN     --> EOTI    (fechamento de input)                  *
      *   EOTI     --> EOFI    (fechamento financeiro)                *
      *   EOFI     --> CLOSED  (fechamento do dia)                    *
      *                                                               *
      * CHAMADA VIA JCL:                                              *
      *   //STEP EXEC PGM=EBCTL01,PARM='OPEN'                        *
      *   //STEP EXEC PGM=EBCTL01,PARM='EOTI'                        *
      *   //STEP EXEC PGM=EBCTL01,PARM='EOFI'                        *
      *   //STEP EXEC PGM=EBCTL01,PARM='CLOSED'                      *
      *                                                               *
      * LAYOUT ARQ.CTL.STATUS (LRECL=8, RECFM=FB):                   *
      *   PIC X(8) com valores: 'OPEN    ' 'EOTI    '                *
      *                         'EOFI    ' 'CLOSED  '                *
      *                                                               *
      * USADO POR: EBJSOD, EBJCUTF, EBJCUTE, EBJEOD                  *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Transicao realizada com sucesso                 *
      *   RC = 8  --> PARM ausente, transicao invalida ou erro de I/O *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CTLSTAT = dataset de status do branch (ARQ.CTL.STATUS)        *
      * Aberto I-O para READ + REWRITE em um unico open               *
      *---------------------------------------------------------------*
           SELECT CTL-STATUS-FILE
               ASSIGN TO CTLSTAT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CTL.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de status (8 bytes)                                   *
      *---------------------------------------------------------------*
       FD  CTL-STATUS-FILE
           RECORD CONTAINS 8 CHARACTERS
           RECORDING MODE IS F.
       01  CTL-STATUS-REG             PIC X(8).
           88 STATUS-VAZIO            VALUE SPACES.
           88 STATUS-OPEN             VALUE 'OPEN    '.
           88 STATUS-EOTI             VALUE 'EOTI    '.
           88 STATUS-EOFI             VALUE 'EOFI    '.
           88 STATUS-CLOSED           VALUE 'CLOSED  '.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status                                                   *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CTL               PIC XX VALUE SPACES.
              88 FS-CTL-OK            VALUE '00'.
              88 FS-CTL-EOF           VALUE '10'.

      *---------------------------------------------------------------*
      * Controles                                                     *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-CTL-ABERTO           PIC X VALUE 'N'.
              88 CTL-ABERTO           VALUE 'S'.
           05 WS-ARQUIVO-VAZIO        PIC X VALUE 'N'.
              88 ARQUIVO-VAZIO        VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

      *---------------------------------------------------------------*
      * Status atual e status destino                                 *
      *---------------------------------------------------------------*
       01  WS-STATUS-ATUAL            PIC X(8) VALUE SPACES.
       01  WS-STATUS-DESTINO          PIC X(8) VALUE SPACES.

      *---------------------------------------------------------------*
      * Data e hora                                                   *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA            PIC 9(8).
       01  WS-HORA-SISTEMA            PIC 9(8).

       LINKAGE SECTION.
      *---------------------------------------------------------------*
      * PARM recebido do JCL via EXEC PGM=EBCTL01,PARM='OPEN'         *
      * PARM-LEN = comprimento do dado (halfword binario)              *
      * PARM-DADOS = conteudo do PARM (ex: 'OPEN', 'EOTI', 'CLOSED')  *
      *---------------------------------------------------------------*
       01  PARM-AREA.
           05 PARM-LEN                PIC S9(4) COMP.
           05 PARM-DADOS              PIC X(8).

       PROCEDURE DIVISION USING PARM-AREA.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME

           PERFORM 1000-VALIDAR-PARM

           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-ABRIR-CTL-STATUS
           END-IF

           IF NAO-OCORREU-ERRO-IO
               PERFORM 3000-LER-STATUS-ATUAL
           END-IF

           IF NAO-OCORREU-ERRO-IO
               PERFORM 4000-VALIDAR-TRANSICAO
           END-IF

           IF NAO-OCORREU-ERRO-IO
               PERFORM 5000-GRAVAR-NOVO-STATUS
           END-IF

           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-DEFINIR-RETURN-CODE
           GOBACK.

      *---------------------------------------------------------------*
      * Valida o PARM recebido e carrega WS-STATUS-DESTINO            *
      *---------------------------------------------------------------*
       1000-VALIDAR-PARM.
           IF PARM-LEN = ZERO
               DISPLAY '*** ERRO: PARM nao informado. '
                       'Use PARM=OPEN|EOTI|EOFI|CLOSED'
               SET OCORREU-ERRO-IO TO TRUE
               EXIT PARAGRAPH
           END-IF

           IF PARM-LEN > 8
               DISPLAY '*** ERRO: PARM muito longo (' PARM-LEN
                       ' bytes). Maximo: 8.'
               SET OCORREU-ERRO-IO TO TRUE
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO WS-STATUS-DESTINO
           MOVE PARM-DADOS(1:PARM-LEN) TO WS-STATUS-DESTINO

           EVALUATE WS-STATUS-DESTINO
               WHEN 'OPEN    '
               WHEN 'EOTI    '
               WHEN 'EOFI    '
               WHEN 'CLOSED  '
                   CONTINUE
               WHEN OTHER
                   DISPLAY '*** ERRO: STATUS DESTINO INVALIDO: ['
                           WS-STATUS-DESTINO ']'
                   DISPLAY '    Valores aceitos: OPEN EOTI EOFI CLOSED'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

      *---------------------------------------------------------------*
      * Abre CTL.STATUS para leitura e reescrita (I-O)                *
      *---------------------------------------------------------------*
       2000-ABRIR-CTL-STATUS.
           OPEN I-O CTL-STATUS-FILE
           IF FS-CTL-OK
               SET CTL-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN CTL-STATUS-FILE - STATUS: '
                       WS-FS-CTL
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Le o status atual do arquivo                                  *
      * Se arquivo vazio (primeiro uso): considera status como SPACES  *
      *---------------------------------------------------------------*
       3000-LER-STATUS-ATUAL.
           READ CTL-STATUS-FILE
               AT END
                   SET ARQUIVO-VAZIO TO TRUE
                   MOVE SPACES TO WS-STATUS-ATUAL
                   DISPLAY '*** AVISO: CTL.STATUS vazio - '
                           'primeiro uso do dia'
               NOT AT END
                   IF FS-CTL-OK
                       MOVE CTL-STATUS-REG TO WS-STATUS-ATUAL
                   ELSE
                       DISPLAY '*** ERRO READ CTL-STATUS - STATUS: '
                               WS-FS-CTL
                       SET OCORREU-ERRO-IO TO TRUE
                   END-IF
           END-READ.

      *---------------------------------------------------------------*
      * Valida se a transicao ATUAL -> DESTINO e permitida            *
      *---------------------------------------------------------------*
       4000-VALIDAR-TRANSICAO.
           EVALUATE TRUE
               WHEN WS-STATUS-ATUAL = SPACES
                    AND WS-STATUS-DESTINO = 'OPEN    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'CLOSED  '
                    AND WS-STATUS-DESTINO = 'OPEN    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'OPEN    '
                    AND WS-STATUS-DESTINO = 'EOTI    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'EOTI    '
                    AND WS-STATUS-DESTINO = 'EOFI    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'EOFI    '
                    AND WS-STATUS-DESTINO = 'CLOSED  '
                   CONTINUE
               WHEN OTHER
                   DISPLAY '*** ERRO: TRANSICAO INVALIDA'
                   DISPLAY '    STATUS ATUAL  : [' WS-STATUS-ATUAL ']'
                   DISPLAY '    STATUS DESTINO: [' WS-STATUS-DESTINO']'
                   DISPLAY '    TRANSICOES VALIDAS:'
                   DISPLAY '      (vazio)  -> OPEN'
                   DISPLAY '      CLOSED   -> OPEN'
                   DISPLAY '      OPEN     -> EOTI'
                   DISPLAY '      EOTI     -> EOFI'
                   DISPLAY '      EOFI     -> CLOSED'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

      *---------------------------------------------------------------*
      * Grava o novo status no arquivo                                *
      * Se arquivo estava vazio: usa WRITE (primeiro registro)        *
      * Se ja havia registro: usa REWRITE (atualiza existente)        *
      *---------------------------------------------------------------*
       5000-GRAVAR-NOVO-STATUS.
           MOVE WS-STATUS-DESTINO TO CTL-STATUS-REG

           IF ARQUIVO-VAZIO
               WRITE CTL-STATUS-REG
               IF NOT FS-CTL-OK
                   DISPLAY '*** ERRO WRITE CTL-STATUS - STATUS: '
                           WS-FS-CTL
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           ELSE
               REWRITE CTL-STATUS-REG
               IF NOT FS-CTL-OK
                   DISPLAY '*** ERRO REWRITE CTL-STATUS - STATUS: '
                           WS-FS-CTL
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               DISPLAY '*** CTL.STATUS ATUALIZADO'
               DISPLAY '    DE  : [' WS-STATUS-ATUAL ']'
               DISPLAY '    PARA: [' WS-STATUS-DESTINO ']'
               DISPLAY '    DATA: ' WS-DATA-SISTEMA
                       ' HORA: '   WS-HORA-SISTEMA
           END-IF.

      *---------------------------------------------------------------*
      * Fecha CTL.STATUS                                              *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF CTL-ABERTO
               CLOSE CTL-STATUS-FILE
               IF NOT FS-CTL-OK
                   DISPLAY '*** ERRO CLOSE CTL-STATUS - STATUS: '
                           WS-FS-CTL
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Define RETURN-CODE                                            *
      *---------------------------------------------------------------*
       9100-DEFINIR-RETURN-CODE.
           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.