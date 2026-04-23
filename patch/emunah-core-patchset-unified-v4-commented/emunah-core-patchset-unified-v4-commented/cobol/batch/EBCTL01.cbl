      *===============================================================*
      * ARQUIVO   : EBCTL01.cbl                                        *
      * CAMINHO   : cobol/batch/EBCTL01.cbl                            *
      *---------------------------------------------------------------*
      * FINALIDADE: Ler, validar e transicionar CTL.STATUS de forma controlada.*
      *                                                               *
      * ENTRADAS  : CTLSTAT + PARM do JCL                          *
      * SAIDAS    : CTLSTAT atualizado                             *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Permite somente as transições                              *
      *   vazias/CLOSED->OPEN->EOTI->EOFI->CLOSED.                   *
      * - Protege o lab contra mudança manual de status fora de      *
      *   ordem.                                                     *
      * - Serve como fonte de verdade técnica para os JCLs de estado.*
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCTL01.
      *===============================================================*
      * PROGRAMA : EBCTL01                                            *
      * FUNCAO   : TRANSICIONAR CTL.STATUS                            *
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
       01  WS-FILE-STATUS.
           05 WS-FS-CTL               PIC XX VALUE SPACES.
              88 FS-CTL-OK            VALUE '00'.
              88 FS-CTL-EOF           VALUE '10'.

       01  WS-CONTROLES.
           05 WS-CTL-ABERTO           PIC X VALUE 'N'.
              88 CTL-ABERTO           VALUE 'S'.
           05 WS-ARQUIVO-VAZIO        PIC X VALUE 'N'.
              88 ARQUIVO-VAZIO        VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

       01  WS-STATUS-ATUAL            PIC X(8) VALUE SPACES.
       01  WS-STATUS-DESTINO          PIC X(8) VALUE SPACES.

       LINKAGE SECTION.
       01  PARM-AREA.
           05 PARM-LEN                PIC S9(4) COMP.
           05 PARM-DADOS              PIC X(8).

       PROCEDURE DIVISION USING PARM-AREA.
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
                   DISPLAY '*** EBCTL01 ERRO - STATUS destino invalido: ['
                           WS-STATUS-DESTINO ']'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

       2000-ABRIR.
           OPEN I-O CTL-STATUS-FILE
           IF FS-CTL-OK
               SET CTL-ABERTO TO TRUE
           ELSE
               DISPLAY '*** EBCTL01 ERRO OPEN CTL.STATUS - STATUS: '
                       WS-FS-CTL
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

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
                   DISPLAY '*** EBCTL01 ERRO - transicao invalida.'
                   DISPLAY '*** ATUAL  : [' WS-STATUS-ATUAL   ']'
                   DISPLAY '*** DESTINO: [' WS-STATUS-DESTINO ']'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

       5000-GRAVAR.
           MOVE WS-STATUS-DESTINO TO STS-CODIGO
           IF ARQUIVO-VAZIO
               WRITE CTL-STATUS-REG
               IF NOT FS-CTL-OK
                   DISPLAY '*** EBCTL01 ERRO WRITE CTL.STATUS - '
                           WS-FS-CTL
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           ELSE
               REWRITE CTL-STATUS-REG
               IF NOT FS-CTL-OK
                   DISPLAY '*** EBCTL01 ERRO REWRITE CTL.STATUS - '
                           WS-FS-CTL
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF NAO-OCORREU-ERRO-IO
               DISPLAY '*** EBCTL01 OK - DE [' WS-STATUS-ATUAL ']'
               DISPLAY '*** EBCTL01 OK - PARA [' WS-STATUS-DESTINO ']'
           END-IF.

       9000-FECHAR.
           IF CTL-ABERTO
               CLOSE CTL-STATUS-FILE
           END-IF.

       9100-RETORNO.
           IF OCORREU-ERRO-IO
               MOVE 8 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
