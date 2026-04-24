*===============================================================*
      * PROGRAMA : EBCTL01                                            *
      * FUNCAO   : TRANSICAO CONTROLADA DO CTL.STATUS                 *
      * MODULO   : CTL (Controle de Estado)                           *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe o status destino via PARM do JCL                     *
      * - Le o status atual do arquivo CTL.STATUS (8 bytes)           *
      * - Valida se a transicao e permitida pela maquina de estados   *
      * - Grava o novo status via WRITE ou REWRITE conforme necessario *
      *                                                               *
      * MAQUINA DE ESTADOS DO LABORATORIO:                            *
      *   (vazio) ou CLOSED --> OPEN   : inicio do ciclo do dia       *
      *   OPEN              --> EOTI   : fim da entrada (batch ok)     *
      *   EOTI              --> EOFI   : fim do processamento          *
      *   EOFI              --> CLOSED : fechamento do dia             *
      * Qualquer outra transicao e rejeitada com RC=8                 *
      *                                                               *
      * ENTRADA:                                                      *
      *   CTLSTAT = Z77948.EMUNAH.CTL.STATUS (8 bytes, RECFM=F)       *
      *   PARM    = status destino passado pelo JCL (ex: 'OPEN')      *
      *                                                               *
      * SAIDA:                                                        *
      *   CTLSTAT = arquivo atualizado com novo status                *
      *                                                               *
      * COPYBOOK UTILIZADO:                                           *
      *   CPSTS001 = layout do CTL.STATUS com level 88 por valor      *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Transicao executada com sucesso                 *
      *   RC = 8  --> PARM invalido, transicao proibida ou erro I/O   *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCTL01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CTL-STATUS-FILE: arquivo de controle de estado do ciclo       *
      * Aberto em I-O para permitir tanto WRITE quanto REWRITE        *
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
      * Os level 88 permitem comparacao legivel (ex: IF STS-OPEN)     *
      *---------------------------------------------------------------*
       FD  CTL-STATUS-FILE
           RECORD CONTAINS 8 CHARACTERS
           RECORDING MODE IS F.
       01  CTL-STATUS-REG.
           COPY CPSTS001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status do CTL.STATUS                                     *
      * '00' = OK   '10' = arquivo vazio (sem registro)               *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CTL               PIC XX VALUE SPACES.
              88 FS-CTL-OK            VALUE '00'.
              88 FS-CTL-EOF           VALUE '10'.

      *---------------------------------------------------------------*
      * Flags de controle                                             *
      * CTL-ABERTO: garante CLOSE seguro no 9000                      *
      * ARQUIVO-VAZIO: diferencia WRITE (primeira vez) de REWRITE     *
      * OCORREU-ERRO-IO: sinaliza falha em qualquer etapa             *
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
      * Status atual (lido do arquivo) e destino (recebido via PARM)  *
      * Ambos com 8 bytes para compatibilidade com os valores do 88   *
      *---------------------------------------------------------------*
       01  WS-STATUS-ATUAL            PIC X(8) VALUE SPACES.
       01  WS-STATUS-DESTINO          PIC X(8) VALUE SPACES.

      *---------------------------------------------------------------*
      * LINKAGE SECTION: area de comunicacao com o JCL via PARM=      *
      * PARM-LEN: comprimento em bytes do dado recebido               *
      * PARM-DADOS: conteudo do PARM (ex: 'OPEN', 'EOTI', 'CLOSED')   *
      *---------------------------------------------------------------*
       LINKAGE SECTION.
       01  PARM-AREA.
           05 PARM-LEN                PIC S9(4) COMP.
           05 PARM-DADOS              PIC X(8).

       PROCEDURE DIVISION USING PARM-AREA.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Fluxo: valida PARM -> abre arquivo -> le status atual ->      *
      * valida transicao -> grava novo status -> encerra              *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-VALIDAR-PARM
           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-ABRIR
           END-IF
           IF NAO-OCORREU-ERRO-IO
               PERFORM 3000-LER-ATUAL
           END-IF
           IF NAO-OCORREU-ERRO-IO
               PERFORM 4000-VALIDAR-TRANSICAO
           END-IF
           IF NAO-OCORREU-ERRO-IO
               PERFORM 5000-GRAVAR
           END-IF
           PERFORM 9000-FECHAR
           PERFORM 9100-RETORNO
           GOBACK.

      *---------------------------------------------------------------*
      * 1000-VALIDAR-PARM                                             *
      * Verifica se o PARM foi fornecido e se o valor e valido        *
      * Valores aceitos: OPEN, EOTI, EOFI, CLOSED (padded com spaces) *
      * PARM vazio ou valor desconhecido resulta em RC=8              *
      *---------------------------------------------------------------*
       1000-VALIDAR-PARM.
           IF PARM-LEN = ZERO
               DISPLAY '*** EBCTL01 ERRO - PARM ausente.'
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
                   DISPLAY '*** EBCTL01 ERRO - STATUS destino invalido'
                           ': [' WS-STATUS-DESTINO ']'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

      *---------------------------------------------------------------*
      * 2000-ABRIR                                                    *
      * Abre o CTL.STATUS em I-O para permitir WRITE e REWRITE        *
      *---------------------------------------------------------------*
       2000-ABRIR.
           OPEN I-O CTL-STATUS-FILE
           IF FS-CTL-OK
               SET CTL-ABERTO TO TRUE
           ELSE
               DISPLAY '*** EBCTL01 ERRO OPEN CTL.STATUS - STATUS: '
                       WS-FS-CTL
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * 3000-LER-ATUAL                                                *
      * Le o status atual do arquivo                                  *
      * AT END = arquivo vazio (primeiro uso do laboratorio)          *
      * Neste caso, WS-STATUS-ATUAL fica em SPACES                    *
      *---------------------------------------------------------------*
       3000-LER-ATUAL.
           READ CTL-STATUS-FILE
               AT END
                   SET ARQUIVO-VAZIO TO TRUE
                   MOVE SPACES TO WS-STATUS-ATUAL
               NOT AT END
                   IF FS-CTL-OK
                       MOVE STS-CODIGO TO WS-STATUS-ATUAL
                   ELSE
                       DISPLAY '*** EBCTL01 ERRO READ CTL.STATUS - '
                               WS-FS-CTL
                       SET OCORREU-ERRO-IO TO TRUE
                   END-IF
           END-READ.

      *---------------------------------------------------------------*
      * 4000-VALIDAR-TRANSICAO                                        *
      * Implementa a maquina de estados do laboratorio                *
      * Apenas as transicoes da sequencia oficial sao permitidas      *
      * Qualquer outro par (atual, destino) resulta em RC=8            *
      *---------------------------------------------------------------*
       4000-VALIDAR-TRANSICAO.
           EVALUATE TRUE
      *        Primeira execucao ou reinicio apos CLOSED
               WHEN WS-STATUS-ATUAL = SPACES
                    AND WS-STATUS-DESTINO = 'OPEN    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'CLOSED  '
                    AND WS-STATUS-DESTINO = 'OPEN    '
                   CONTINUE
      *        Progressao normal do ciclo do dia
               WHEN WS-STATUS-ATUAL = 'OPEN    '
                    AND WS-STATUS-DESTINO = 'EOTI    '
                   CONTINUE