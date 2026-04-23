      *===============================================================*
      * ARQUIVO   : EBPCHK01.cbl                                       *
      * CAMINHO   : cobol/batch/EBPCHK01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Validar o conteúdo de CTL.STATUS durante o precheck da cadeia.*
      *                                                               *
      * ENTRADAS  : CTLSTAT                                        *
      * SAIDAS    : SYSOUT/SYSPRINT e RETURN-CODE do step          *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Aceita arquivo vazio.                                      *
      * - Aceita status CLOSED.                                      *
      * - Rejeita OPEN, EOTI e EOFI antes do início de um novo dia.  *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBPCHK01.
      *===============================================================*
      * PROGRAMA : EBPCHK01                                           *
      * FUNCAO   : VALIDAR CTL.STATUS NO PRECHECK                     *
      *                                                               *
      * REGRAS:                                                       *
      * - aceita arquivo vazio                                        *
      * - aceita CLOSED                                               *
      * - rejeita OPEN / EOTI / EOFI                                  *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CTL-STATUS-FILE
               ASSIGN TO CTLSTAT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CTL.

       DATA DIVISION.
       FILE SECTION.
       FD  CTL-STATUS-FILE
           RECORD CONTAINS 8 CHARACTERS
           RECORDING MODE IS F.
       01  CTL-STATUS-REG.
           COPY CPSTS001.

       WORKING-STORAGE SECTION.
       01  WS-FS-CTL                  PIC XX VALUE SPACES.
           88 FS-CTL-OK               VALUE '00'.
           88 FS-CTL-EOF              VALUE '10'.

       01  WS-FLAGS.
           05 WS-CTL-ABERTO           PIC X VALUE 'N'.
              88 CTL-ABERTO           VALUE 'S'.
           05 WS-ERRO                 PIC X VALUE 'N'.
              88 COM-ERRO             VALUE 'S'.
           05 WS-ARQ-VAZIO            PIC X VALUE 'N'.
              88 ARQ-VAZIO            VALUE 'S'.

       01  WS-STATUS-LIDO             PIC X(08) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR
           IF NOT COM-ERRO
               PERFORM 2000-LER
           END-IF
           PERFORM 3000-VALIDAR
           PERFORM 9000-FECHAR
           GOBACK.

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

       3000-VALIDAR.
           IF COM-ERRO
               EXIT PARAGRAPH
           END-IF

           DISPLAY '*** EBPCHK01 STATUS ENCONTRADO: [' WS-STATUS-LIDO ']'

           EVALUATE TRUE
               WHEN ARQ-VAZIO
                   DISPLAY '*** EBPCHK01 OK - CTL.STATUS vazio.'
                   MOVE 0 TO RETURN-CODE
               WHEN WS-STATUS-LIDO = 'CLOSED  '
                   DISPLAY '*** EBPCHK01 OK - ciclo anterior fechado.'
                   MOVE 0 TO RETURN-CODE
               WHEN OTHER
                   DISPLAY '*** EBPCHK01 FALHA - CTL.STATUS invalido '
                           'para inicio de cadeia.'
                   DISPLAY '*** VALORES ACEITOS: [        ] OU [CLOSED  ]'
                   MOVE 8 TO RETURN-CODE
           END-EVALUATE.

       9000-FECHAR.
           IF CTL-ABERTO
               CLOSE CTL-STATUS-FILE
           END-IF.
