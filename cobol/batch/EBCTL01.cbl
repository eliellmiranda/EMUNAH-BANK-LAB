      *===============================================================*
      * PROGRAMA : EBCTL01                                            *
      * FUNCAO   : TRANSICAO E VALIDACAO DO CTL.STATUS                *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCTL01.

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

      *--- Variaveis de parse do JCL PARM ----------------------------*
       01  WS-ACAO                    PIC X(3) VALUE SPACES.
       01  WS-STATUS-ATUAL            PIC X(8) VALUE SPACES.
       01  WS-STATUS-ALVO             PIC X(8) VALUE SPACES.

       LINKAGE SECTION.
       01  PARM-AREA.
           05 PARM-LEN                PIC S9(4) COMP.
           05 PARM-DADOS              PIC X(100).

       PROCEDURE DIVISION USING PARM-AREA.

       0000-PRINCIPAL.
           PERFORM 1000-VALIDAR-PARM

           IF NAO-OCORREU-ERRO-IO
               PERFORM 2000-ABRIR
           END-IF
           IF NAO-OCORREU-ERRO-IO
               PERFORM 3000-LER-ATUAL
           END-IF

      * Fluxo de Atualizacao (UPD)
           IF NAO-OCORREU-ERRO-IO AND WS-ACAO = 'UPD'
               PERFORM 4000-VALIDAR-TRANSICAO
               IF NAO-OCORREU-ERRO-IO
                   PERFORM 5000-GRAVAR
               END-IF
           END-IF

      * Fluxo de Checagem Passiva (CHK)
           IF NAO-OCORREU-ERRO-IO AND WS-ACAO = 'CHK'
               PERFORM 6000-CHECAR-STATUS
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

      * Extrai ACAO e STATUS_ALVO do formato 'ACAO,STATUS'
           MOVE SPACES TO WS-ACAO WS-STATUS-ALVO
           UNSTRING PARM-DADOS(1:PARM-LEN) DELIMITED BY ','
               INTO WS-ACAO
                    WS-STATUS-ALVO
           END-UNSTRING

           IF WS-ACAO NOT = 'CHK' AND WS-ACAO NOT = 'UPD'
               DISPLAY '*** EBCTL01 ERRO - ACAO INVALIDA: ' WS-ACAO
               SET OCORREU-ERRO-IO TO TRUE
               EXIT PARAGRAPH
           END-IF

           EVALUATE WS-STATUS-ALVO
               WHEN 'OPEN    '
               WHEN 'EOTI    '
               WHEN 'EOFI    '
               WHEN 'CLOSED  '
                   CONTINUE
               WHEN OTHER
                   DISPLAY '*** EBCTL01 ERRO - STATUS ALVO INVALIDO'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

       2000-ABRIR.
      * Se for apenas validacao (CHK), abre apenas leitura.
      * CORRECAO: Se for UPD, tambem abre INPUT apenas para ler
      * o estado atual. A gravacao sera feita reabrindo em OUTPUT.
           OPEN INPUT CTL-STATUS-FILE

           IF FS-CTL-OK
               SET CTL-ABERTO TO TRUE
           ELSE
               DISPLAY '*** EBCTL01 ERRO OPEN - STATUS: ' WS-FS-CTL
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
                       DISPLAY '*** EBCTL01 ERRO READ - FS: ' WS-FS-CTL
                       SET OCORREU-ERRO-IO TO TRUE
                   END-IF
           END-READ.

       4000-VALIDAR-TRANSICAO.
      * Mantida a logica original da maquina de estados para UPD
           EVALUATE TRUE
               WHEN WS-STATUS-ATUAL = SPACES AND
                    WS-STATUS-ALVO = 'OPEN    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'CLOSED  ' AND
                    WS-STATUS-ALVO = 'OPEN    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'OPEN    ' AND
                    WS-STATUS-ALVO = 'EOTI    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'EOTI    ' AND
                    WS-STATUS-ALVO = 'EOFI    '
                   CONTINUE
               WHEN WS-STATUS-ATUAL = 'EOFI    ' AND
                    WS-STATUS-ALVO = 'CLOSED  '
                   CONTINUE
               WHEN OTHER
                   DISPLAY '*** EBCTL01 ERRO - TRANSICAO INVALIDA'
                   DISPLAY '    ATUAL : [' WS-STATUS-ATUAL ']'
                   DISPLAY '    DESTINO : [' WS-STATUS-ALVO ']'
                   SET OCORREU-ERRO-IO TO TRUE
           END-EVALUATE.

       5000-GRAVAR.
           MOVE WS-STATUS-ALVO TO STS-CODIGO
           
      * CORRECAO: Arquivo fisico sequencial (PS) nao suporta REWRITE
      * Fecha a leitura e reabre em OUTPUT para truncar e gravar novo
           CLOSE CTL-STATUS-FILE
           OPEN OUTPUT CTL-STATUS-FILE
           
           IF FS-CTL-OK
               WRITE CTL-STATUS-REG
               IF NOT FS-CTL-OK
                   DISPLAY '*** EBCTL01 ERRO I/O (WRITE) - FS: ' 
                            WS-FS-CTL
                   SET OCORREU-ERRO-IO TO TRUE
               ELSE
                   DISPLAY '*** EBCTL01 - ATUALIZADO PARA: [' 
                            WS-STATUS-ALVO ']'
               END-IF
           ELSE
               DISPLAY '*** EBCTL01 ERRO REOPEN OUTPUT - FS: ' 
                        WS-FS-CTL
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

       6000-CHECAR-STATUS.
      * Se o arquivo estiver vazio, logicamente conta como CLOSED
           IF ARQUIVO-VAZIO AND WS-STATUS-ALVO = 'CLOSED  '
               MOVE 'CLOSED  ' TO WS-STATUS-ATUAL
           END-IF

           IF WS-STATUS-ATUAL = WS-STATUS-ALVO
               DISPLAY '*** EBCTL01 - CHECAGEM OK. STATUS: ['
                        WS-STATUS-ATUAL ']'
           ELSE
               DISPLAY '*** EBCTL01 ERRO - CHECAGEM FALHOU'
               DISPLAY '    STATUS ESPERADO: [' WS-STATUS-ALVO ']'
               DISPLAY '    STATUS ENCONTRADO: [' WS-STATUS-ATUAL ']'
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

       9000-FECHAR.
           IF CTL-ABERTO
               CLOSE CTL-STATUS-FILE
               IF NOT FS-CTL-OK
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

       9100-RETORNO.
           IF OCORREU-ERRO-IO
               MOVE 8 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.