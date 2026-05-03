      *===============================================================*
      * PROGRAMA : EBPCHK01                                           *
      * FUNCAO   : PRECHECK DO CTL.STATUS ANTES DO INICIO DA CADEIA   *
      * MODULO   : CTL (Controle de Estado)                           *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o arquivo CTL.STATUS (8 bytes)                           *
      * - Valida se o status permite o inicio de um novo ciclo        *
      * - Emite mensagem descritiva no SYSOUT                         *
      * - Define RETURN-CODE para controle do JCL via COND ou IF      *
      *                                                               *
      * LOGICA DE VALIDACAO:                                          *
      *   Arquivo vazio (AT END) --> OK: laboratorio nunca iniciado   *
      *   Status = CLOSED        --> OK: ciclo anterior encerrado     *
      *   Status = OPEN          --> FALHA: dia ja foi aberto         *
      *   Status = EOTI          --> FALHA: batch em andamento        *
      *   Status = EOFI          --> FALHA: aguardando fechamento     *
      *                                                               *
      * QUANDO USAR:                                                  *
      * - Primeiro step da cadeia batch do dia (EBJLOAD, EBJVALD...)  *
      * - Impede reexecucao acidental da cadeia com ciclo em aberto   *
      * - RC=8 no precheck deve acionar COND no JCL para abortar      *
      *                                                               *
      * ENTRADA:                                                      *
      *   CTLSTAT = Z77948.EMUNAH.CTL.STATUS (8 bytes, RECFM=F)       *
      *                                                               *
      * COPYBOOK UTILIZADO:                                           *
      *   CPSTS001 = layout do CTL.STATUS com level 88 por valor      *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Status aceito, cadeia pode prosseguir           *
      *   RC = 8  --> Status invalido para inicio ou erro I/O         *
      *   RC = 12 --> Erro critico no OPEN do arquivo                 *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBPCHK01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CTL-STATUS-FILE: arquivo de controle de estado do ciclo       *
      * Aberto em INPUT — apenas leitura, sem alteracao               *
      * DDNAME: CTLSTAT   LRECL: 8   RECFM: F                         *
      *---------------------------------------------------------------*
           SELECT CTL-STATUS-FILE
               ASSIGN TO CTLSTAT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CTL.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Registro de status — layout via CPSTS001                      *
      * Level 88 permitem validacao por nome (STS-OPEN, STS-CLOSED)   *
      *---------------------------------------------------------------*
       FD  CTL-STATUS-FILE
           RECORD CONTAINS 8 CHARACTERS
           RECORDING MODE IS F.
       01  CTL-STATUS-REG.
           COPY CPSTS001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status do CTL.STATUS                                     *
      * '00' = OK   '10' = arquivo vazio (AT END)                     *
      *---------------------------------------------------------------*
       01  WS-FS-CTL                  PIC XX VALUE SPACES.
           88 FS-CTL-OK               VALUE '00'.
           88 FS-CTL-EOF              VALUE '10'.

      *---------------------------------------------------------------*
      * Flags de controle                                             *
      * CTL-ABERTO: garante CLOSE seguro no paragrafo de encerramento *
      * COM-ERRO: sinaliza falha de I/O                               *
      * ARQ-VAZIO: indica que o arquivo nao tem registro (AT END)     *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-CTL-ABERTO           PIC X VALUE 'N'.
              88 CTL-ABERTO           VALUE 'S'.
           05 WS-ERRO                 PIC X VALUE 'N'.
              88 COM-ERRO             VALUE 'S'.
           05 WS-ARQ-VAZIO            PIC X VALUE 'N'.
              88 ARQ-VAZIO            VALUE 'S'.

      *---------------------------------------------------------------*
      * Status lido do arquivo para exibicao no SYSOUT                *
      * Preenchido no READ ou mantido em SPACES se AT END             *
      *---------------------------------------------------------------*
       01  WS-STATUS-LIDO             PIC X(08) VALUE SPACES.

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Fluxo: abre arquivo -> le status -> valida -> encerra         *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR
           IF NOT COM-ERRO
               PERFORM 2000-LER
           END-IF
           PERFORM 3000-VALIDAR
           PERFORM 9000-FECHAR
           GOBACK.

      *---------------------------------------------------------------*
      * 1000-ABRIR                                                    *
      * Erro de OPEN resulta em RC=12 — erro critico antes de ler     *
      *---------------------------------------------------------------*
       1000-ABRIR.
           OPEN INPUT CTL-STATUS-FILE
           IF FS-CTL-OK
               SET CTL-ABERTO TO TRUE
           ELSE
               DISPLAY '*** EBPCHK01 ERRO OPEN CTL.STATUS - STATUS: '
                       WS-FS-CTL
               SET COM-ERRO TO TRUE
               MOVE 12 TO RETURN-CODE
           END-IF.

      *---------------------------------------------------------------*
      * 2000-LER                                                      *
      * Le o unico registro do arquivo                                *
      * AT END: arquivo sem registro — laboratorio em estado inicial  *
      * NOT AT END: captura o status gravado pelo EBCTL01             *
      *---------------------------------------------------------------*
       2000-LER.
           READ CTL-STATUS-FILE
               AT END
                   SET ARQ-VAZIO TO TRUE
                   MOVE SPACES TO WS-STATUS-LIDO
               NOT AT END
                   IF FS-CTL-OK
                       MOVE STS-CODIGO TO WS-STATUS-LIDO
                   ELSE
                       DISPLAY '*** EBPCHK01 ERRO READ CTL.STATUS - '
                               WS-FS-CTL
                       SET COM-ERRO TO TRUE
                       MOVE 12 TO RETURN-CODE
                   END-IF
           END-READ.

      *---------------------------------------------------------------*
      * 3000-VALIDAR                                                  *
      * Exibe o status encontrado e avalia se permite novo ciclo      *
      *                                                               *
      * Aceito (RC=0):                                                *
      *   - Arquivo vazio: primeira execucao do laboratorio           *
      *   - CLOSED: ciclo anterior foi encerrado corretamente         *
      *                                                               *
      * Rejeitado (RC=8):                                             *
      *   - OPEN: dia ja aberto — cadeia nao deve reiniciar           *
      *   - EOTI: batch em andamento — aguardar conclusao             *
      *   - EOFI: aguardando fechamento — executar EBJEOD01 primeiro  *
      *---------------------------------------------------------------*
       3000-VALIDAR.
           IF COM-ERRO
               EXIT PARAGRAPH
           END-IF

           DISPLAY '*** EBPCHK01 STATUS ENCONTRADO: ['
                   WS-STATUS-LIDO ']'

           EVALUATE TRUE
               WHEN ARQ-VAZIO
                   DISPLAY '*** EBPCHK01 OK - CTL.STATUS vazio.'
                   DISPLAY '*** EBPCHK01 OK - Primeiro ciclo do lab.'
                   MOVE 0 TO RETURN-CODE
               WHEN WS-STATUS-LIDO = 'CLOSED  '
                   DISPLAY '*** EBPCHK01 OK - Ciclo anterior fechado.'
                   DISPLAY '*** EBPCHK01 OK - Cadeia autorizada.'
                   MOVE 0 TO RETURN-CODE
               WHEN OTHER
                   DISPLAY '*** EBPCHK01 FALHA - CTL.STATUS invalido '
                           'para inicio de cadeia.'
                   DISPLAY '*** EBPCHK01 VALORES ACEITOS: '
                           '[        ] OU [CLOSED  ]'
                   DISPLAY '*** EBPCHK01 VERIFICAR STATUS ATUAL ANTES'
                           ' DE REEXECUTAR A CADEIA.'
                   MOVE 8 TO RETURN-CODE
           END-EVALUATE.

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      * Fecha o arquivo apenas se foi aberto com sucesso              *
      *---------------------------------------------------------------*
       9000-FECHAR.
           IF CTL-ABERTO
               CLOSE CTL-STATUS-FILE
           END-IF.