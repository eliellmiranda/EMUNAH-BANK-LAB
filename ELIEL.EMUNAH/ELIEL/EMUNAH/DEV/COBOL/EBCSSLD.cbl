       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSSLD.
      *===============================================================*
      * PROGRAMA : EBCSSLD                                            *
      * BIBLIOTECA: ELIEL.EMUNAH.ONLINE.COBOL                        *
      * FUNCAO   : CONSULTA DE SALDO VIA CICS                        *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe agencia e conta via tela BMS (mapa EBMSLD)           *
      * - Faz leitura direta (EXEC CICS READ) no KSDS EMCONTA         *
      * - Enriquece saldo com SELECT em EMUNAH.CDCNT (DB2)            *
      * - Exibe na tela: saldo atual, limite e saldo disponivel       *
      *   Saldo disponivel = CNT-SALDO + CNT-LIMITE                   *
      * - Trata conta nao encontrada (NOTFND) e outros erros I/O      *
      *                                                               *
      * TRANSACAO CICS: ESLD                                          *
      * MAPA BMS: EBMSLD (copybook EBMSLD.cpy)                        *
      * ARQUIVO CICS: EMCONTA (VSAM KSDS de contas)                   *
      * DB2 PLAN: EBCSSLD (BIND PLAN PKLIST EMUNAH.*)                 *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *===============================================================*
      * DB2 HOST VARIABLES                                            *
      *                                                               *
      * REGRA 1 — POSICAO:                                            *
      *   BEGIN DECLARE SECTION DEVE ser o primeiro item da           *
      *   WORKING-STORAGE, antes de qualquer COPY ou EXEC SQL.        *
      *                                                               *
      * REGRA 2 — TIPO:                                               *
      *   PIC S9(n) COMP      -> mapeia INTEGER/SMALLINT (DB2)        *
      *   PIC S9(n)V99 COMP-3 -> mapeia DECIMAL (DB2)                 *
      *   PIC X(n)            -> mapeia CHAR/VARCHAR (DB2)             *
      *   PIC 9(n) sem S e sem COMP = DISPLAY unsigned = UNUSABLE     *
      *                                                               *
      * REGRA 3 — ESTRUTURA:                                          *
      *   Host variables em nivel 01 individual. WS-SQLCODE-ED nao   *
      *   e host variable — fica FORA do BEGIN/END DECLARE SECTION.   *
      *===============================================================*
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

      *---------------------------------------------------------------*
      * HV-AGENCIA   : chave da agencia  — S9(4)  COMP = SMALLINT DB2*
      * HV-NUM-CONTA : numero da conta   — S9(9)  COMP = INTEGER  DB2*
      * HV-CNT-SALDO : saldo da conta    — DECIMAL(13,2) no DB2       *
      * HV-CNT-LIMITE: limite de credito — DECIMAL(13,2) no DB2       *
      *---------------------------------------------------------------*
       01  HV-AGENCIA            PIC S9(4)      COMP.
       01  HV-NUM-CONTA          PIC S9(9)      COMP.
       01  HV-CNT-SALDO          PIC S9(11)V99  COMP-3.
       01  HV-CNT-LIMITE         PIC S9(11)V99  COMP-3.

           EXEC SQL END DECLARE SECTION END-EXEC.

      *---------------------------------------------------------------*
      * SQLCA — deve vir APOS o END DECLARE SECTION                   *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.

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
      * Mantida como DISPLAY para compatibilidade com a chave VSAM    *
      *---------------------------------------------------------------*
       01  WS-CHAVE-CONTA.
           05 WS-AGENCIA               PIC 9(4).
           05 WS-NUM-CONTA             PIC 9(8).

      *---------------------------------------------------------------*
      * Campos de edicao para exibir valores monetarios na tela       *
      * PIC Z(7)9,99 suprime zeros a esquerda                         *
      *---------------------------------------------------------------*
       01  WS-SALDO-EDIT               PIC Z(7)9,99.
       01  WS-LIMITE-EDIT              PIC Z(7)9,99.
       01  WS-DISPONIVEL-EDIT          PIC Z(7)9,99.

      *---------------------------------------------------------------*
      * Saldo disponivel calculado antes da edicao                    *
      *---------------------------------------------------------------*
       01  WS-SALDO-DISPONIVEL         PIC S9(11)V99 COMP-3.

      *---------------------------------------------------------------*
      * Mensagem para o campo MSGO da tela                            *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO              PIC X(50).

      *---------------------------------------------------------------*
      * Mensagem de encerramento da transacao                         *
      *---------------------------------------------------------------*
       01  WS-MSG-FIM                  PIC X(24)
           VALUE 'TRANSACAO ESLD ENCERRADA'.

      *---------------------------------------------------------------*
      * Campo de edicao para log do SQLCODE — NAO e host variable     *
      *---------------------------------------------------------------*
       01  WS-SQLCODE-ED               PIC S9(9) COMP.

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
                   PERFORM 2500-CONSULTAR-SALDO-DB2
                   PERFORM 3000-MONTAR-RESPOSTA
               WHEN DFHRESP(NOTFND)
                   MOVE 'CONTA NAO ENCONTRADA' TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
               WHEN OTHER
                   MOVE 'ERRO DE LEITURA NO VSAM' TO WS-MSG-RETORNO
                   PERFORM 8000-ENVIAR-ERRO
           END-EVALUATE.

      *===============================================================*
      * 2500-CONSULTAR-SALDO-DB2                                      *
      * SELECT saldo e limite direto do DB2 (EMUNAH.CDCNT).           *
      * COBOL converte automaticamente:                               *
      *   WS-AGENCIA   9(4)  DISPLAY -> HV-AGENCIA   S9(4)  COMP     *
      *   WS-NUM-CONTA 9(8)  DISPLAY -> HV-NUM-CONTA S9(9)  COMP     *
      * SQLCODE  0  : OK, sobrescreve VSAM com valor DB2              *
      * SQLCODE 100 : conta nao existe no DB2, usa dado VSAM          *
      * OTHER       : erro DB2, loga SQLCODE em CSSL via WRITEQ TD    *
      *===============================================================*
       2500-CONSULTAR-SALDO-DB2.
           MOVE WS-AGENCIA   TO HV-AGENCIA
           MOVE WS-NUM-CONTA TO HV-NUM-CONTA

           EXEC SQL
               SELECT CNT_SALDO,
                      CNT_LIMITE
               INTO  :HV-CNT-SALDO,
                     :HV-CNT-LIMITE
               FROM   EMUNAH.CDCNT
               WHERE  CNT_AGENCIA   = :HV-AGENCIA
               AND    CNT_NUM_CONTA = :HV-NUM-CONTA
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   MOVE HV-CNT-SALDO  TO CNT-SALDO  OF WS-CONTA-REG
                   MOVE HV-CNT-LIMITE TO CNT-LIMITE OF WS-CONTA-REG
               WHEN 100
      *            Conta nao existe no DB2: dado VSAM permanece
                   CONTINUE
               WHEN OTHER
      *            Erro DB2: loga SQLCODE no TD CSSL, VSAM permanece
                   MOVE SQLCODE TO WS-SQLCODE-ED
                   EXEC CICS WRITEQ TD
                       QUEUE('CSSL')
                       FROM(WS-SQLCODE-ED)
                       LENGTH(4)
                   END-EXEC
           END-EVALUATE.

      *===============================================================*
      * 3000-MONTAR-RESPOSTA                                          *
      * Calcula saldo disponivel e edita os tres valores monetarios.  *
      *===============================================================*
       3000-MONTAR-RESPOSTA.
           MOVE CNT-SALDO  OF WS-CONTA-REG TO WS-SALDO-EDIT
           MOVE CNT-LIMITE OF WS-CONTA-REG TO WS-LIMITE-EDIT

           ADD CNT-SALDO  OF WS-CONTA-REG
               CNT-LIMITE OF WS-CONTA-REG
               GIVING WS-SALDO-DISPONIVEL
           MOVE WS-SALDO-DISPONIVEL TO WS-DISPONIVEL-EDIT

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
      * Acionado por PF3 ou CLEAR.                                    *
      *===============================================================*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM(WS-MSG-FIM)
               LENGTH(24)
               ERASE
           END-EXEC

           EXEC CICS RETURN
           END-EXEC.
