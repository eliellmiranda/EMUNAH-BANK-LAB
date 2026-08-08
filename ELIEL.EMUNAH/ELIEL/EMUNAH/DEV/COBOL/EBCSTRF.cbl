       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSTRF.
      *===============================================================*
      * PROGRAMA : EBCSTRF                                            *
      * BIBLIOTECA: ELIEL.EMUNAH.ONLINE.COBOL                        *
      * FUNCAO   : TRANSFERENCIA ENTRE CONTAS VIA CICS               *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe via tela EBMTRF: agencia/conta origem, agencia/conta *
      *   destino e valor da transferencia                            *
      * - Le a conta origem com UPDATE (bloqueia para escrita)        *
      * - Verifica saldo disponivel: CNT-SALDO + CNT-LIMITE >= VALOR  *
      * - Le a conta destino com UPDATE                               *
      * - Debita o valor da origem e credita no destino               *
      * - Faz REWRITE em ambas as contas e exibe confirmacao          *
      * - Faz UNLOCK e exibe erro em caso de falha em qualquer etapa  *
      *                                                               *
      * TRANSACAO CICS: ETRF                                          *
      * MAPA BMS: EBMTRF (copybook EBMTRF.cpy)                        *
      * ARQUIVO CICS: EMCONTA (VSAM KSDS de contas)                   *
      *                                                               *
      * CONTROLE TRANSACIONAL:                                        *
      * - READ com UPDATE obtem lock exclusivo no registro            *
      * - REWRITE libera o lock apos a atualizacao                   *
      * - UNLOCK libera o lock sem gravar (em caso de erro)           *
      * - A ausencia de syncpoint explicito delega o commit/rollback  *
      *   ao CICS ao final da task (RETURN)                           *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Copybook do mapa BMS de transferencia                         *
      * Gera EBMTRFI (input) e EBMTRFO (output)                       *
      * Campos de input: AGORIGI, CTORIGI, AGDESTI, CTDESTI, VALORI   *
      * Campos de output: SLDORIGO, SLDDESTO, MSGO                    *
      *---------------------------------------------------------------*
       COPY EBMTRF.

      *---------------------------------------------------------------*
      * Areas de trabalho para os registros das duas contas           *
      * Ambas usam o mesmo layout CPCNT001                            *
      *---------------------------------------------------------------*
       01  WS-CONTA-ORIG.
           COPY CPCNT001.

       01  WS-CONTA-DEST.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Variaveis de resposta CICS                                    *
      *---------------------------------------------------------------*
       01  WS-RESP                    PIC S9(8) COMP.
       01  WS-RESP2                   PIC S9(8) COMP.

      *---------------------------------------------------------------*
      * Chaves de leitura para origem e destino                       *
      * Cada chave = agencia(4) + conta(8) = 12 bytes                 *
      *---------------------------------------------------------------*
       01  WS-CHAVE-ORIG.
           05 WS-AG-ORIG              PIC 9(4).
           05 WS-CT-ORIG              PIC 9(8).

       01  WS-CHAVE-DEST.
           05 WS-AG-DEST              PIC 9(4).
           05 WS-CT-DEST              PIC 9(8).

      *---------------------------------------------------------------*
      * Valor da transferencia recebido da tela                       *
      *---------------------------------------------------------------*
       01  WS-VALOR-TRF               PIC 9(11)V99 VALUE ZERO.
       01  WS-VALOR-EDIT              PIC ZZZ.ZZZ.ZZ9,99.

      *---------------------------------------------------------------*
      * Edicao dos saldos apos a transferencia para exibicao na tela  *
      * PIC -ZZZ.ZZZ.ZZ9,99 admite saldo negativo (conta com limite)  *
      *---------------------------------------------------------------*
       01  WS-SALDO-ORIG-EDIT         PIC -ZZZ.ZZZ.ZZ9,99.
       01  WS-SALDO-DEST-EDIT         PIC -ZZZ.ZZZ.ZZ9,99.

      *---------------------------------------------------------------*
      * Mensagem para o campo MSGO do mapa de saida                   *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO             PIC X(60).
      *---------------------------------------------------------------*
      * Mensagem de encerramento da transacao                         *
      *---------------------------------------------------------------*
       01  WS-MSG-FIM                  PIC X(24)
           VALUE 'TRANSACAO ETRF ENCERRADA'.

       PROCEDURE DIVISION.
      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Fluxo CICS: define AID, recebe mapa EBMTRF e despacha.        *
      * EXEC CICS RETURN com TRANSID mantem a transacao ativa.        *
      *===============================================================*
       0000-PRINCIPAL.
           EXEC CICS HANDLE AID
               PF3(9000-ENCERRAR)
               CLEAR(9000-ENCERRAR)
           END-EXEC

           EXEC CICS RECEIVE MAP('EBMTRF')
               MAPSET('EBMTRF')
               INTO(EBMTRFI)
               RESP(WS-RESP)
           END-EXEC

           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 1000-VALIDAR-ENTRADA
           ELSE
               MOVE 'ERRO AO RECEBER DADOS DA TELA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           END-IF

           EXEC CICS RETURN
               TRANSID('ETRF')
           END-EXEC.

      *===============================================================*
      * 1000-VALIDAR-ENTRADA                                          *
      * Todos os 5 campos sao obrigatorios. SPACES indica que o       *
      * operador deixou o campo vazio.                                *
      *===============================================================*
       1000-VALIDAR-ENTRADA.
           IF AGORIGI OF EBMTRFI = SPACES
              OR CTORIGI OF EBMTRFI = SPACES
              OR AGDESTI OF EBMTRFI = SPACES
              OR CTDESTI OF EBMTRFI = SPACES
              OR VALORI  OF EBMTRFI = SPACES
               MOVE 'PREENCHA TODOS OS CAMPOS' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE AGORIGI OF EBMTRFI TO WS-AG-ORIG
               MOVE CTORIGI OF EBMTRFI TO WS-CT-ORIG
               MOVE AGDESTI OF EBMTRFI TO WS-AG-DEST
               MOVE CTDESTI OF EBMTRFI TO WS-CT-DEST
               MOVE VALORI  OF EBMTRFI TO WS-VALOR-TRF
               PERFORM 2000-EXECUTAR-TRANSFERENCIA
           END-IF.

      *===============================================================*
      * 2000-EXECUTAR-TRANSFERENCIA                                   *
      * Valida valor > zero antes de prosseguir.                      *
      *===============================================================*
       2000-EXECUTAR-TRANSFERENCIA.
           IF WS-VALOR-TRF <= ZERO
               MOVE 'VALOR DEVE SER MAIOR QUE ZERO'
                   TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               PERFORM 2100-LER-CONTA-ORIGEM
           END-IF.

      *===============================================================*
      * 2100-LER-CONTA-ORIGEM                                         *
      * READ com UPDATE bloqueia o registro da conta origem.          *
      * O lock so e liberado com REWRITE ou UNLOCK.                   *
      *===============================================================*
       2100-LER-CONTA-ORIGEM.
           EXEC CICS READ
               FILE('EMCONTA')
               INTO(WS-CONTA-ORIG)
               RIDFLD(WS-CHAVE-ORIG)
               UPDATE
               RESP(WS-RESP)
           END-EXEC

           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                   PERFORM 2200-VALIDAR-SALDO-ORIGEM
               WHEN DFHRESP(NOTFND)
                   MOVE 'CONTA ORIGEM NAO ENCONTRADA'
                       TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
               WHEN OTHER
                   MOVE 'ERRO LEITURA CONTA ORIGEM'
                       TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
           END-EVALUATE.

      *===============================================================*
      * 2200-VALIDAR-SALDO-ORIGEM                                     *
      * Saldo disponivel = saldo atual + limite de credito.           *
      * Se insuficiente: UNLOCK libera o lock antes de retornar erro. *
      *===============================================================*
       2200-VALIDAR-SALDO-ORIGEM.
           IF CNT-SALDO  OF WS-CONTA-ORIG +
              CNT-LIMITE OF WS-CONTA-ORIG < WS-VALOR-TRF
               MOVE 'SALDO INSUFICIENTE PARA TRANSFERENCIA'
                   TO WS-MSG-RETORNO
      *-- Libera lock sem gravar -----------------------------------*
               EXEC CICS UNLOCK
                   FILE('EMCONTA')
               END-EXEC
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               PERFORM 2300-LER-CONTA-DESTINO
           END-IF.

      *===============================================================*
      * 2300-LER-CONTA-DESTINO                                        *
      * READ com UPDATE na conta destino. Se nao encontrada ou erro,  *
      * UNLOCK libera o lock da origem antes de exibir erro.          *
      *===============================================================*
       2300-LER-CONTA-DESTINO.
           EXEC CICS READ
               FILE('EMCONTA')
               INTO(WS-CONTA-DEST)
               RIDFLD(WS-CHAVE-DEST)
               UPDATE
               RESP(WS-RESP)
           END-EXEC

           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                   PERFORM 3000-EFETIVAR-TRANSFERENCIA
               WHEN DFHRESP(NOTFND)
                   MOVE 'CONTA DESTINO NAO ENCONTRADA'
                       TO WS-MSG-RETORNO
                   EXEC CICS UNLOCK
                       FILE('EMCONTA')
                   END-EXEC
                   PERFORM 8000-ENVIAR-ERRO
               WHEN OTHER
                   MOVE 'ERRO LEITURA CONTA DESTINO'
                       TO WS-MSG-RETORNO
                   EXEC CICS UNLOCK
                       FILE('EMCONTA')
                   END-EXEC
                   PERFORM 8000-ENVIAR-ERRO
           END-EVALUATE.

      *===============================================================*
      * 3000-EFETIVAR-TRANSFERENCIA                                   *
      * Atualiza saldos em memoria e regrava ambos os registros.      *
      * Sequencia: SUBTRACT origem -> REWRITE origem -> ADD destino   *
      * -> REWRITE destino.                                           *
      * Se REWRITE origem falhar, o lock da origem nao e liberado     *
      * pelo REWRITE; o rollback fica a cargo do CICS no RETURN.      *
      *===============================================================*
       3000-EFETIVAR-TRANSFERENCIA.
      *-- Atualiza saldos em working-storage ----------------------*
           SUBTRACT WS-VALOR-TRF FROM
               CNT-SALDO OF WS-CONTA-ORIG
           ADD WS-VALOR-TRF TO
               CNT-SALDO OF WS-CONTA-DEST

      *-- Regrava a conta origem (libera lock da origem) ----------*
           EXEC CICS REWRITE
               FILE('EMCONTA')
               FROM(WS-CONTA-ORIG)
               RESP(WS-RESP)
           END-EXEC

           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO ATUALIZANDO CONTA ORIGEM'
                   TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
      *-- Regrava a conta destino (libera lock do destino) --------*
               EXEC CICS REWRITE
                   FILE('EMCONTA')
                   FROM(WS-CONTA-DEST)
                   RESP(WS-RESP)
               END-EXEC

               IF WS-RESP NOT = DFHRESP(NORMAL)
                   MOVE 'ERRO ATUALIZANDO CONTA DESTINO'
                       TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
               ELSE
                   PERFORM 4000-CONFIRMAR-TRANSFERENCIA
               END-IF
           END-IF.

      *===============================================================*
      * 4000-CONFIRMAR-TRANSFERENCIA                                  *
      * Monta tela de confirmacao com saldos pos-transferencia.       *
      *===============================================================*
       4000-CONFIRMAR-TRANSFERENCIA.
           MOVE WS-VALOR-TRF                    TO WS-VALOR-EDIT
           MOVE CNT-SALDO OF WS-CONTA-ORIG      TO WS-SALDO-ORIG-EDIT
           MOVE CNT-SALDO OF WS-CONTA-DEST      TO WS-SALDO-DEST-EDIT

           MOVE WS-SALDO-ORIG-EDIT TO SLDORIGO OF EBMTRFO
           MOVE WS-SALDO-DEST-EDIT TO SLDDESTO OF EBMTRFO
           MOVE 'TRANSFERENCIA REALIZADA COM SUCESSO'
               TO MSGO OF EBMTRFO

           EXEC CICS SEND MAP('EBMTRF')
               MAPSET('EBMTRF')
               FROM(EBMTRFO)
               ERASE
           END-EXEC.

      *===============================================================*
      * 8000-ENVIAR-ERRO                                              *
      * Copia mensagem de erro para MSGO e envia mapa ao terminal.    *
      *===============================================================*
       8000-ENVIAR-ERRO.
           MOVE WS-MSG-RETORNO TO MSGO OF EBMTRFO
           EXEC CICS SEND MAP('EBMTRF')
               MAPSET('EBMTRF')
               FROM(EBMTRFO)
               ERASE
           END-EXEC.

      *===============================================================*
      * 9000-ENCERRAR                                                 *
      * Acionado por PF3 ou CLEAR. Encerra sem manter transid.        *
      *===============================================================*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM(WS-MSG-FIM)
               LENGTH(24)
               ERASE
           END-EXEC

           EXEC CICS RETURN
           END-EXEC.
