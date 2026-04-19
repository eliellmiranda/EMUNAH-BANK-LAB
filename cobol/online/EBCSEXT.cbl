       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSEXT.
      *===============================================================*
      * PROGRAMA : EBCSEXT                                            *
      * FUNCAO   : CONSULTA DE EXTRATO VIA CICS                      *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe agencia e conta via tela BMS (mapa EBMEXT)           *
      * - Le os movimentos do VSAM ESDS (browse sequencial)          *
      * - Filtra apenas movimentos da conta informada                 *
      * - Exibe ate 15 linhas de extrato por pagina                   *
      * - Totaliza creditos e debitos exibidos                        *
      *                                                               *
      * TRANSACAO CICS: EEXT                                          *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular uma consulta online de extrato bancario             *
      * - Praticar browse em VSAM via CICS                            *
      * - Demonstrar paginacao de registros                           *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Copybook do mapa BMS de extrato                               *
      *---------------------------------------------------------------*
       COPY EBMEXT.

      *---------------------------------------------------------------*
      * Area para registro de movimento lido do VSAM                  *
      *---------------------------------------------------------------*
       01  WS-MOVTO-REG.
           05 WS-MV-AGENCIA           PIC 9(4).
           05 WS-MV-CONTA             PIC 9(8).
           05 WS-MV-DATA              PIC 9(8).
           05 WS-MV-TIPO              PIC X(1).
           05 WS-MV-VALOR             PIC 9(11)V99.
           05 WS-MV-HISTORICO         PIC X(30).
           05 WS-MV-CANAL             PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Controles                                                     *
      *---------------------------------------------------------------*
       01  WS-RESP                    PIC S9(8) COMP.
       01  WS-RESP2                   PIC S9(8) COMP.
       01  WS-LINHAS                  PIC 9(2) VALUE ZERO.
       01  WS-MAX-LINHAS              PIC 9(2) VALUE 15.
       01  WS-FIM-BROWSE              PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Chave e filtro                                                *
      *---------------------------------------------------------------*
       01  WS-AGENCIA-FILTRO          PIC 9(4).
       01  WS-CONTA-FILTRO            PIC 9(8).
       01  WS-RBA                     PIC S9(8) COMP VALUE ZERO.

      *---------------------------------------------------------------*
      * Totalizadores                                                 *
      *---------------------------------------------------------------*
       01  WS-TOTAL-CREDITOS          PIC 9(11)V99 VALUE ZERO.
       01  WS-TOTAL-DEBITOS           PIC 9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Edicao                                                        *
      *---------------------------------------------------------------*
       01  WS-VALOR-EDIT              PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-TOTAL-CRED-EDIT         PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-TOTAL-DEB-EDIT          PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-DATA-FMT                PIC X(10).

      *---------------------------------------------------------------*
      * Mensagens                                                     *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO             PIC X(50).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL CICS                                          *
      *===============================================================*
       0000-PRINCIPAL.
           EXEC CICS HANDLE AID
               PF3(9000-ENCERRAR)
               CLEAR(9000-ENCERRAR)
           END-EXEC

           EXEC CICS RECEIVE MAP('EBMEXT')
               MAPSET('EBMEXT')
               INTO(EBMEXTI)
               RESP(WS-RESP)
           END-EXEC

           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 1000-VALIDAR-ENTRADA
           ELSE
               MOVE 'ERRO AO RECEBER DADOS DA TELA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           END-IF

           EXEC CICS RETURN
               TRANSID('EEXT')
           END-EXEC.

      *---------------------------------------------------------------*
      * Valida dados e inicia browse                                  *
      *---------------------------------------------------------------*
       1000-VALIDAR-ENTRADA.
           IF AGENCIAI OF EBMEXTI = SPACES
              OR CONTAI OF EBMEXTI = SPACES
               MOVE 'INFORME AGENCIA E CONTA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE AGENCIAI OF EBMEXTI TO WS-AGENCIA-FILTRO
               MOVE CONTAI OF EBMEXTI   TO WS-CONTA-FILTRO
               PERFORM 2000-BROWSE-MOVIMENTOS
           END-IF.

      *---------------------------------------------------------------*
      * Browse no VSAM ESDS de lancamentos                            *
      *---------------------------------------------------------------*
       2000-BROWSE-MOVIMENTOS.
           MOVE ZERO TO WS-RBA

           EXEC CICS STARTBR
               FILE('EMLANCTO')
               RIDFLD(WS-RBA)
               RBA
               RESP(WS-RESP)
           END-EXEC

           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO AO ABRIR BROWSE' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               PERFORM 2100-LER-PROXIMO
                   UNTIL WS-FIM-BROWSE = 'S'
                      OR WS-LINHAS >= WS-MAX-LINHAS

               EXEC CICS ENDBR
                   FILE('EMLANCTO')
               END-EXEC

               PERFORM 3000-MONTAR-TOTAIS
           END-IF.

      *---------------------------------------------------------------*
      * Le proximo registro e filtra pela conta                       *
      *---------------------------------------------------------------*
       2100-LER-PROXIMO.
           EXEC CICS READNEXT
               FILE('EMLANCTO')
               INTO(WS-MOVTO-REG)
               RIDFLD(WS-RBA)
               RBA
               RESP(WS-RESP)
           END-EXEC

           IF WS-RESP = DFHRESP(ENDFILE)
              OR WS-RESP = DFHRESP(NOTFND)
               MOVE 'S' TO WS-FIM-BROWSE
           ELSE
               IF WS-RESP = DFHRESP(NORMAL)
                   IF WS-MV-AGENCIA = WS-AGENCIA-FILTRO
                      AND WS-MV-CONTA = WS-CONTA-FILTRO
                       ADD 1 TO WS-LINHAS
                       PERFORM 2200-MONTAR-LINHA
                   END-IF
               ELSE
                   MOVE 'S' TO WS-FIM-BROWSE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Monta uma linha de extrato na tela                            *
      *---------------------------------------------------------------*
       2200-MONTAR-LINHA.
           MOVE WS-MV-VALOR TO WS-VALOR-EDIT

           STRING WS-MV-DATA(7:2) '/'
                  WS-MV-DATA(5:2) '/'
                  WS-MV-DATA(1:4)
                  DELIMITED BY SIZE
                  INTO WS-DATA-FMT
           END-STRING

           IF WS-MV-TIPO = 'C'
               ADD WS-MV-VALOR TO WS-TOTAL-CREDITOS
           ELSE
               ADD WS-MV-VALOR TO WS-TOTAL-DEBITOS
           END-IF.

      *---------------------------------------------------------------*
      * Monta totais na area de rodape da tela                        *
      *---------------------------------------------------------------*
       3000-MONTAR-TOTAIS.
           MOVE WS-TOTAL-CREDITOS TO WS-TOTAL-CRED-EDIT
           MOVE WS-TOTAL-DEBITOS  TO WS-TOTAL-DEB-EDIT

           IF WS-LINHAS = ZERO
               MOVE 'NENHUM MOVIMENTO ENCONTRADO' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE 'EXTRATO CONSULTADO COM SUCESSO'
                   TO MSGO OF EBMEXTO

               EXEC CICS SEND MAP('EBMEXT')
                   MAPSET('EBMEXT')
                   FROM(EBMEXTO)
                   ERASE
               END-EXEC
           END-IF.

      *---------------------------------------------------------------*
      * Envia mensagem de erro                                        *
      *---------------------------------------------------------------*
       8000-ENVIAR-ERRO.
           MOVE WS-MSG-RETORNO TO MSGO OF EBMEXTO
           EXEC CICS SEND MAP('EBMEXT')
               MAPSET('EBMEXT')
               FROM(EBMEXTO)
               ERASE
           END-EXEC.

      *---------------------------------------------------------------*
      * Encerra a transacao                                           *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM('TRANSACAO EEXT ENCERRADA')
               ERASE
           END-EXEC
           EXEC CICS RETURN END-EXEC.
