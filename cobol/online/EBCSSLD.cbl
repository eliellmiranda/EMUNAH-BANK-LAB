       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSSLD.
      *===============================================================*
      * PROGRAMA : EBCSSLD                                            *
      * FUNCAO   : CONSULTA DE SALDO VIA CICS                        *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe agencia e conta via tela BMS (mapa EBMSLD)           *
      * - Busca a conta no VSAM KSDS                                 *
      * - Exibe saldo atual, limite e saldo disponivel na tela        *
      * - Trata conta nao encontrada e erros de I/O                   *
      *                                                               *
      * TRANSACAO CICS: ESLD                                          *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular uma consulta online de saldo bancario               *
      * - Praticar programacao CICS com RECEIVE MAP / SEND MAP        *
      * - Demonstrar integracao CICS + VSAM                           *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Copybook do mapa BMS de saldo                                 *
      *---------------------------------------------------------------*
       COPY EBMSLD.

      *---------------------------------------------------------------*
      * Copybook do registro de conta                                 *
      *---------------------------------------------------------------*
       01  WS-CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Area de comunicacao CICS                                      *
      *---------------------------------------------------------------*
       01  WS-RESP                     PIC S9(8) COMP.
       01  WS-RESP2                    PIC S9(8) COMP.

      *---------------------------------------------------------------*
      * Chave para leitura no VSAM                                    *
      *---------------------------------------------------------------*
       01  WS-CHAVE-CONTA.
           05 WS-AGENCIA               PIC 9(4).
           05 WS-NUM-CONTA             PIC 9(8).

      *---------------------------------------------------------------*
      * Campos de edicao para exibicao na tela                        *
      *---------------------------------------------------------------*
       01  WS-SALDO-EDIT               PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-LIMITE-EDIT              PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-DISPONIVEL-EDIT          PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-SALDO-DISPONIVEL         PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Mensagens de retorno                                          *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO              PIC X(50).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL CICS                                          *
      *===============================================================*
       0000-PRINCIPAL.
           EXEC CICS HANDLE AID
               PF3(9000-ENCERRAR)
               CLEAR(9000-ENCERRAR)
           END-EXEC

           EXEC CICS RECEIVE MAP('EBMSLD')
               MAPSET('EBMSLD')
               INTO(EBMSLDI)
               RESP(WS-RESP)
           END-EXEC

           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 1000-VALIDAR-ENTRADA
           ELSE
               MOVE 'ERRO AO RECEBER DADOS DA TELA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           END-IF

           EXEC CICS RETURN
               TRANSID('ESLD')
           END-EXEC.

      *---------------------------------------------------------------*
      * Valida entrada e consulta a conta                             *
      *---------------------------------------------------------------*
       1000-VALIDAR-ENTRADA.
           IF AGENCIAI OF EBMSLDI = SPACES
              OR CONTAI OF EBMSLDI = SPACES
               MOVE 'INFORME AGENCIA E CONTA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE AGENCIAI OF EBMSLDI TO WS-AGENCIA
               MOVE CONTAI OF EBMSLDI   TO WS-NUM-CONTA
               PERFORM 2000-CONSULTAR-CONTA
           END-IF.

      *---------------------------------------------------------------*
      * Busca a conta no VSAM                                        *
      *---------------------------------------------------------------*
       2000-CONSULTAR-CONTA.
           EXEC CICS READ
               FILE('EMCONTA')
               INTO(WS-CONTA-REG)
               RIDFLD(WS-CHAVE-CONTA)
               RESP(WS-RESP)
               RESP2(WS-RESP2)
           END-EXEC

           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                   PERFORM 3000-MONTAR-RESPOSTA
               WHEN DFHRESP(NOTFND)
                   MOVE 'CONTA NAO ENCONTRADA' TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
               WHEN OTHER
                   MOVE 'ERRO DE LEITURA NO VSAM' TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
           END-EVALUATE.

      *---------------------------------------------------------------*
      * Monta os campos de resposta na tela                           *
      *---------------------------------------------------------------*
       3000-MONTAR-RESPOSTA.
           MOVE CNT-SALDO OF WS-CONTA-REG TO WS-SALDO-EDIT
           MOVE CNT-LIMITE OF WS-CONTA-REG TO WS-LIMITE-EDIT

           ADD CNT-SALDO OF WS-CONTA-REG
               CNT-LIMITE OF WS-CONTA-REG
               GIVING WS-SALDO-DISPONIVEL
           MOVE WS-SALDO-DISPONIVEL TO WS-DISPONIVEL-EDIT

           MOVE WS-SALDO-EDIT      TO SALDOO OF EBMSLDO
           MOVE WS-LIMITE-EDIT     TO LIMITEO OF EBMSLDO
           MOVE WS-DISPONIVEL-EDIT TO DISPON OF EBMSLDO
           MOVE CNT-STATUS OF WS-CONTA-REG TO STATUSO OF EBMSLDO
           MOVE CNT-TIPO OF WS-CONTA-REG   TO TIPOO OF EBMSLDO
           MOVE 'CONSULTA REALIZADA COM SUCESSO'
               TO MSGO OF EBMSLDO

           EXEC CICS SEND MAP('EBMSLD')
               MAPSET('EBMSLD')
               FROM(EBMSLDO)
               ERASE
           END-EXEC.

      *---------------------------------------------------------------*
      * Envia mensagem de erro                                        *
      *---------------------------------------------------------------*
       8000-ENVIAR-ERRO.
           MOVE WS-MSG-RETORNO TO MSGO OF EBMSLDO
           EXEC CICS SEND MAP('EBMSLD')
               MAPSET('EBMSLD')
               FROM(EBMSLDO)
               ERASE
           END-EXEC.

      *---------------------------------------------------------------*
      * Encerra a transacao                                           *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM('TRANSACAO ESLD ENCERRADA')
               ERASE
           END-EXEC
           EXEC CICS RETURN END-EXEC.
