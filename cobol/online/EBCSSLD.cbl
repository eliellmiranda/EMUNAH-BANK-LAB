       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSSLD.
      *===============================================================*
      * PROGRAMA : EBCSSLD                                            *
      * BIBLIOTECA: Z77948.EMUNAH.ONLINE.COBOL                        *
      * FUNCAO   : CONSULTA DE SALDO VIA CICS                        *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe agencia e conta via tela BMS (mapa EBMSLD)           *
      * - Faz leitura direta (EXEC CICS READ) no KSDS EMCONTA         *
      * - Exibe na tela: saldo atual, limite e saldo disponivel       *
      *   Saldo disponivel = CNT-SALDO + CNT-LIMITE                   *
      * - Trata conta nao encontrada (NOTFND) e outros erros I/O      *
      *                                                               *
      * TRANSACAO CICS: ESLD                                          *
      * MAPA BMS: EBMSLD (copybook EBMSLD.cpy)                        *
      * ARQUIVO CICS: EMCONTA (VSAM KSDS de contas)                   *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Copybook do mapa BMS de saldo                                 *
      * Gera EBMSLDI (area de input) e EBMSLDO (area de output)       *
      *---------------------------------------------------------------*
       COPY EBMSLD.

      *---------------------------------------------------------------*
      * Area de trabalho para o registro de conta lido do KSDS        *
      * Layout definido pelo copybook CPCNT001:                        *
      * CNT-CHAVE (12), CNT-TIPO (1), CNT-STATUS (1),                 *
      * CNT-SALDO S9(11)V99 COMP-3, CNT-LIMITE S9(11)V99 COMP-3       *
      *---------------------------------------------------------------*
       01  WS-CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Campos CICS para verificar resultado de cada comando           *
      * RESP  = codigo primario de resposta (DFHRESP)                  *
      * RESP2 = codigo secundario (detalhe do erro)                   *
      *---------------------------------------------------------------*
       01  WS-RESP                     PIC S9(8) COMP.
       01  WS-RESP2                    PIC S9(8) COMP.

      *---------------------------------------------------------------*
      * Chave composta para READ no KSDS                              *
      * Deve espelhar o RECORD KEY do arquivo: agencia(4)+conta(8)    *
      *---------------------------------------------------------------*
       01  WS-CHAVE-CONTA.
           05 WS-AGENCIA               PIC 9(4).
           05 WS-NUM-CONTA             PIC 9(8).

      *---------------------------------------------------------------*
      * Campos de edicao para exibir valores monetarios na tela       *
      * PIC ZZZ.ZZZ.ZZ9,99 suprime zeros a esquerda                   *
      *---------------------------------------------------------------*
       01  WS-SALDO-EDIT               PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-LIMITE-EDIT              PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-DISPONIVEL-EDIT          PIC ZZZ.ZZZ.ZZ9,99.

      *---------------------------------------------------------------*
      * Saldo disponivel calculado antes da edicao                    *
      * Disponivel = saldo atual + limite de credito                  *
      *---------------------------------------------------------------*
       01  WS-SALDO-DISPONIVEL         PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Mensagem para o campo MSGO da tela                            *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO              PIC X(50).
      *---------------------------------------------------------------*
      * Mensagem de encerramento da transacao                         *
      *---------------------------------------------------------------*
       01  WS-MSG-FIM                  PIC X(24) 
           VALUE 'TRANSACAO ESLD ENCERRADA'.

       PROCEDURE DIVISION.
      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Fluxo CICS: define AID, recebe mapa e despacha para validacao.*
      * EXEC CICS RETURN com TRANSID mantem transacao ativa.          *
      *===============================================================*
       0000-PRINCIPAL.
      *-- Tecla PF3 ou CLEAR encerram a transacao ------------------*
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

      *===============================================================*
      * 1000-VALIDAR-ENTRADA                                          *
      * Verifica preenchimento dos campos obrigatorios.               *
      * Campos SPACES indicam que o operador nao preencheu a tela.   *
      *===============================================================*
       1000-VALIDAR-ENTRADA.
           IF AGENCIAI OF EBMSLDI = SPACES
              OR CONTAI OF EBMSLDI = SPACES
               MOVE 'INFORME AGENCIA E CONTA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE AGENCIAI OF EBMSLDI TO WS-AGENCIA
               MOVE CONTAI   OF EBMSLDI TO WS-NUM-CONTA
               PERFORM 2000-CONSULTAR-CONTA
           END-IF.

      *===============================================================*
      * 2000-CONSULTAR-CONTA                                          *
      * EXEC CICS READ faz leitura direta por chave no KSDS.         *
      * DFHRESP(NORMAL) = registro encontrado                         *
      * DFHRESP(NOTFND) = conta inexistente no cadastro               *
      * OTHER           = erro de I/O ou recurso indisponivel         *
      *===============================================================*
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

      *===============================================================*
      * 3000-MONTAR-RESPOSTA                                          *
      * Calcula saldo disponivel e edita os tres valores monetarios.  *
      * Preenche campos do mapa de saida e envia a tela ao terminal.  *
      *===============================================================*
       3000-MONTAR-RESPOSTA.
      *-- Edita saldo e limite para exibicao ----------------------*
           MOVE CNT-SALDO  OF WS-CONTA-REG TO WS-SALDO-EDIT
           MOVE CNT-LIMITE OF WS-CONTA-REG TO WS-LIMITE-EDIT

      *-- Saldo disponivel = saldo atual + limite de credito ------*
           ADD CNT-SALDO  OF WS-CONTA-REG
               CNT-LIMITE OF WS-CONTA-REG
               GIVING WS-SALDO-DISPONIVEL
           MOVE WS-SALDO-DISPONIVEL TO WS-DISPONIVEL-EDIT

      *-- Preenche campos do mapa de saida ------------------------*
           MOVE WS-SALDO-EDIT      TO SALDOO   OF EBMSLDO
           MOVE WS-LIMITE-EDIT     TO LIMITEO  OF EBMSLDO
           MOVE WS-DISPONIVEL-EDIT TO DISPON   OF EBMSLDO
           MOVE CNT-STATUS OF WS-CONTA-REG TO STATUSO OF EBMSLDO
           MOVE CNT-TIPO   OF WS-CONTA-REG TO TIPOO   OF EBMSLDO
           MOVE 'CONSULTA REALIZADA COM SUCESSO'
               TO MSGO OF EBMSLDO

           EXEC CICS SEND MAP('EBMSLD')
               MAPSET('EBMSLD')
               FROM(EBMSLDO)
               ERASE
           END-EXEC.

      *===============================================================*
      * 8000-ENVIAR-ERRO                                              *
      * Copia mensagem de erro para MSGO e envia o mapa ao terminal.  *
      *===============================================================*
       8000-ENVIAR-ERRO.
           MOVE WS-MSG-RETORNO TO MSGO OF EBMSLDO
           EXEC CICS SEND MAP('EBMSLD')
               MAPSET('EBMSLD')
               FROM(EBMSLDO)
               ERASE
           END-EXEC.

      *===============================================================*
      * 9000-ENCERRAR                                                 *
      * Acionado por PF3 ou CLEAR. Exibe texto de encerramento e      *
      * retorna ao CICS sem manter transid.                           *
      *===============================================================*
      *===============================================================*
      * 9000-ENCERRAR                                                 *
      * Acionado por PF3 ou CLEAR. Exibe texto de encerramento e      *
      * retorna ao CICS sem manter transid.                           *
      *===============================================================*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM(WS-MSG-FIM)
               LENGTH(24)
               ERASE
           END-EXEC
           
           EXEC CICS RETURN 
           END-EXEC.