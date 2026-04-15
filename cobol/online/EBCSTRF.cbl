       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSTRF.
      *===============================================================*
      * PROGRAMA : EBCSTRF                                            *
      * FUNCAO   : TRANSFERENCIA ENTRE CONTAS VIA CICS               *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe dados da transferencia via tela BMS (mapa EBMTRF)    *
      *   (agencia/conta origem, agencia/conta destino, valor)        *
      * - Valida se ambas as contas existem no VSAM                   *
      * - Verifica se a conta origem tem saldo suficiente              *
      * - Debita a conta origem e credita a conta destino              *
      * - Grava registro no VSAM ESDS de lancamentos                  *
      * - Exibe confirmacao ou erro na tela                           *
      *                                                               *
      * TRANSACAO CICS: ETRF                                          *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular uma transferencia bancaria online                   *
      * - Praticar atualizacao de VSAM via CICS com UPDATE            *
      * - Demonstrar controle transacional com dois registros         *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Copybook do mapa BMS de transferencia                         *
      *---------------------------------------------------------------*
       COPY EBMTRF.

      *---------------------------------------------------------------*
      * Areas para registros de conta origem e destino                *
      *---------------------------------------------------------------*
       01  WS-CONTA-ORIG.
           COPY CPCNT001.

       01  WS-CONTA-DEST.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Controles CICS                                                *
      *---------------------------------------------------------------*
       01  WS-RESP                    PIC S9(8) COMP.
       01  WS-RESP2                   PIC S9(8) COMP.

      *---------------------------------------------------------------*
      * Chaves de leitura                                             *
      *---------------------------------------------------------------*
       01  WS-CHAVE-ORIG.
           05 WS-AG-ORIG              PIC 9(4).
           05 WS-CT-ORIG              PIC 9(8).

       01  WS-CHAVE-DEST.
           05 WS-AG-DEST              PIC 9(4).
           05 WS-CT-DEST              PIC 9(8).

      *---------------------------------------------------------------*
      * Valor da transferencia                                        *
      *---------------------------------------------------------------*
       01  WS-VALOR-TRF               PIC 9(11)V99 VALUE ZERO.
       01  WS-VALOR-EDIT              PIC ZZZ.ZZZ.ZZ9,99.

      *---------------------------------------------------------------*
      * Edicao de saldos                                              *
      *---------------------------------------------------------------*
       01  WS-SALDO-ORIG-EDIT         PIC -ZZZ.ZZZ.ZZ9,99.
       01  WS-SALDO-DEST-EDIT         PIC -ZZZ.ZZZ.ZZ9,99.

      *---------------------------------------------------------------*
      * Mensagens                                                     *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO             PIC X(60).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL CICS                                          *
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

      *---------------------------------------------------------------*
      * Valida campos obrigatorios                                    *
      *---------------------------------------------------------------*
       1000-VALIDAR-ENTRADA.
           IF AGORIGI OF EBMTRFI = SPACES
              OR CTORIGI OF EBMTRFI = SPACES
              OR AGDESTI OF EBMTRFI = SPACES
              OR CTDESTI OF EBMTRFI = SPACES
              OR VALORI OF EBMTRFI = SPACES
               MOVE 'PREENCHA TODOS OS CAMPOS' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE AGORIGI OF EBMTRFI TO WS-AG-ORIG
               MOVE CTORIGI OF EBMTRFI TO WS-CT-ORIG
               MOVE AGDESTI OF EBMTRFI TO WS-AG-DEST
               MOVE CTDESTI OF EBMTRFI TO WS-CT-DEST
               MOVE VALORI OF EBMTRFI  TO WS-VALOR-TRF
               PERFORM 2000-EXECUTAR-TRANSFERENCIA
           END-IF.

      *---------------------------------------------------------------*
      * Executa a transferencia com controle transacional              *
      *---------------------------------------------------------------*
       2000-EXECUTAR-TRANSFERENCIA.
           IF WS-VALOR-TRF <= ZERO
               MOVE 'VALOR DEVE SER MAIOR QUE ZERO'
                   TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               PERFORM 2100-LER-CONTA-ORIGEM
           END-IF.

      *---------------------------------------------------------------*
      * Le a conta origem com UPDATE                                  *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * Verifica saldo suficiente (saldo + limite)                    *
      *---------------------------------------------------------------*
       2200-VALIDAR-SALDO-ORIGEM.
           IF CNT-SALDO OF WS-CONTA-ORIG +
              CNT-LIMITE OF WS-CONTA-ORIG < WS-VALOR-TRF
               MOVE 'SALDO INSUFICIENTE PARA TRANSFERENCIA'
                   TO WS-MSG-RETORNO
               EXEC CICS UNLOCK
                   FILE('EMCONTA')
               END-EXEC
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               PERFORM 2300-LER-CONTA-DESTINO
           END-IF.

      *---------------------------------------------------------------*
      * Le a conta destino                                            *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * Atualiza saldos e regrava ambas as contas                     *
      *---------------------------------------------------------------*
       3000-EFETIVAR-TRANSFERENCIA.
           SUBTRACT WS-VALOR-TRF FROM
               CNT-SALDO OF WS-CONTA-ORIG
           ADD WS-VALOR-TRF TO
               CNT-SALDO OF WS-CONTA-DEST

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

      *---------------------------------------------------------------*
      * Monta tela de confirmacao                                     *
      *---------------------------------------------------------------*
       4000-CONFIRMAR-TRANSFERENCIA.
           MOVE WS-VALOR-TRF TO WS-VALOR-EDIT
           MOVE CNT-SALDO OF WS-CONTA-ORIG TO WS-SALDO-ORIG-EDIT
           MOVE CNT-SALDO OF WS-CONTA-DEST TO WS-SALDO-DEST-EDIT

           MOVE WS-SALDO-ORIG-EDIT TO SLDORIGO OF EBMTRFO
           MOVE WS-SALDO-DEST-EDIT TO SLDDESTO OF EBMTRFO
           MOVE 'TRANSFERENCIA REALIZADA COM SUCESSO'
               TO MSGO OF EBMTRFO

           EXEC CICS SEND MAP('EBMTRF')
               MAPSET('EBMTRF')
               FROM(EBMTRFO)
               ERASE
           END-EXEC.

      *---------------------------------------------------------------*
      * Envia mensagem de erro                                        *
      *---------------------------------------------------------------*
       8000-ENVIAR-ERRO.
           MOVE WS-MSG-RETORNO TO MSGO OF EBMTRFO
           EXEC CICS SEND MAP('EBMTRF')
               MAPSET('EBMTRF')
               FROM(EBMTRFO)
               ERASE
           END-EXEC.

      *---------------------------------------------------------------*
      * Encerra a transacao                                           *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM('TRANSACAO ETRF ENCERRADA')
               ERASE
           END-EXEC
           EXEC CICS RETURN END-EXEC.
