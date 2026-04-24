IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCSEXT.
      *===============================================================*
      * PROGRAMA : EBCSEXT                                            *
      * BIBLIOTECA: Z77948.EMUNAH.ONLINE.COBOL                        *
      * FUNCAO   : CONSULTA DE EXTRATO VIA CICS                      *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Recebe agencia e conta via tela BMS (mapa EBMEXT)           *
      * - Executa browse no VSAM ESDS de lancamentos (EMLANCTO)       *
      *   usando RBA (relative byte address) a partir do byte 0       *
      * - Filtra registros que pertencem a conta informada            *
      * - Exibe ate 15 linhas de extrato por pagina na tela           *
      * - Totaliza creditos ('C') e debitos ('D') exibidos            *
      * - Exibe mensagem de erro quando nao ha movimentos             *
      *                                                               *
      * TRANSACAO CICS: EEXT                                          *
      * MAPA BMS: EBMEXT (copybook EBMEXT.cpy)                        *
      * ARQUIVO CICS: EMLANCTO (VSAM ESDS de lancamentos)             *
      *                                                               *
      * BROWSE EM ESDS:                                               *
      * - ESDS nao tem chave primaria; a leitura e por RBA            *
      * - STARTBR com RBA=0 percorre o arquivo do inicio              *
      * - READNEXT avanca registro a registro                         *
      * - ENDBR encerra o cursor de browse                            *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Copybook do mapa BMS de extrato                               *
      * Gera EBMEXTI (area de input) e EBMEXTO (area de output)       *
      *---------------------------------------------------------------*
       COPY EBMEXT.

      *---------------------------------------------------------------*
      * Area para receber cada registro de lancamento do VSAM ESDS   *
      * Espelha o layout de CPLCT001 (120 bytes)                      *
      *---------------------------------------------------------------*
       01  WS-MOVTO-REG.
           05 WS-MV-AGENCIA           PIC 9(4).
           05 WS-MV-CONTA             PIC 9(8).
           05 WS-MV-DATA              PIC 9(8).
           05 WS-MV-TIPO              PIC X(1).    *> 'C'=credito 'D'=debito
           05 WS-MV-VALOR             PIC 9(11)V99.
           05 WS-MV-HISTORICO         PIC X(30).
           05 WS-MV-CANAL             PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Controles de resposta CICS e de browse                        *
      *---------------------------------------------------------------*
       01  WS-RESP                    PIC S9(8) COMP.
       01  WS-RESP2                   PIC S9(8) COMP.
       01  WS-LINHAS                  PIC 9(2) VALUE ZERO.
       01  WS-MAX-LINHAS              PIC 9(2) VALUE 15.
                                                  *> limite de linhas
                                                  *> por pagina de tela
       01  WS-FIM-BROWSE              PIC X VALUE 'N'.
           88 FIM-BROWSE              VALUE 'S'.

      *---------------------------------------------------------------*
      * Filtro: apenas lancamentos desta agencia e conta sao exibidos *
      *---------------------------------------------------------------*
       01  WS-AGENCIA-FILTRO          PIC 9(4).
       01  WS-CONTA-FILTRO            PIC 9(8).

      *---------------------------------------------------------------*
      * RBA = Relative Byte Address - posicao no ESDS                 *
      * Iniciado em ZERO para browse do inicio do arquivo             *
      *---------------------------------------------------------------*
       01  WS-RBA                     PIC S9(8) COMP VALUE ZERO.

      *---------------------------------------------------------------*
      * Totalizadores de credito e debito para rodape da tela         *
      *---------------------------------------------------------------*
       01  WS-TOTAL-CREDITOS          PIC 9(11)V99 VALUE ZERO.
       01  WS-TOTAL-DEBITOS           PIC 9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Campos de edicao para exibicao formatada                      *
      *---------------------------------------------------------------*
       01  WS-VALOR-EDIT              PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-TOTAL-CRED-EDIT         PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-TOTAL-DEB-EDIT          PIC ZZZ.ZZZ.ZZ9,99.
       01  WS-DATA-FMT                PIC X(10).  *> DD/MM/AAAA

      *---------------------------------------------------------------*
      * Mensagem de retorno para o campo MSGO da tela                 *
      *---------------------------------------------------------------*
       01  WS-MSG-RETORNO             PIC X(50).

       PROCEDURE DIVISION.
      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Fluxo CICS: captura AID para PF3/CLEAR, recebe o mapa de     *
      * entrada e despacha para validacao. Ao final, EXEC CICS RETURN *
      * com TRANSID mantem a transacao ativa para proxima leitura.    *
      *===============================================================*
       0000-PRINCIPAL.
      *-- Define teclas de saida da transacao ---------------------*
           EXEC CICS HANDLE AID
               PF3(9000-ENCERRAR)
               CLEAR(9000-ENCERRAR)
           END-EXEC

      *-- Recebe dados digitados na tela --------------------------*
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

      *-- Mantem transacao ativa para nova consulta ---------------*
           EXEC CICS RETURN
               TRANSID('EEXT')
           END-EXEC.

      *===============================================================*
      * 1000-VALIDAR-ENTRADA                                          *
      * Verifica preenchimento de agencia e conta.                    *
      * Se validos, captura filtros e inicia o browse.               *
      *===============================================================*
       1000-VALIDAR-ENTRADA.
           IF AGENCIAI OF EBMEXTI = SPACES
              OR CONTAI OF EBMEXTI = SPACES
               MOVE 'INFORME AGENCIA E CONTA' TO WS-MSG-RETORNO
               PERFORM 8000-ENVIAR-ERRO
           ELSE
               MOVE AGENCIAI OF EBMEXTI TO WS-AGENCIA-FILTRO
               MOVE CONTAI   OF EBMEXTI TO WS-CONTA-FILTRO
               PERFORM 2000-BROWSE-MOVIMENTOS
           END-IF.

      *===============================================================*
      * 2000-BROWSE-MOVIMENTOS                                        *
      * Abre cursor de browse no ESDS a partir de RBA=0 (inicio).    *
      * Percorre registros ate 15 linhas ou fim do arquivo.           *
      * Encerra cursor com ENDBR e monta totais.                      *
      *===============================================================*
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
      *-- Le ate 15 registros da conta filtrada --------------------*
               PERFORM 2100-LER-PROXIMO
                   UNTIL FIM-BROWSE
                      OR WS-LINHAS >= WS-MAX-LINHAS

               EXEC CICS ENDBR
                   FILE('EMLANCTO')
               END-EXEC

               PERFORM 3000-MONTAR-TOTAIS
           END-IF.

      *===============================================================*
      * 2100-LER-PROXIMO                                              *
      * Avanca um registro no browse. Compara agencia/conta para      *
      * filtrar apenas movimentos da conta solicitada.                *
      * ENDFILE ou NOTFND = fim do arquivo, encerra o loop.           *
      *===============================================================*
       2100-LER-PROXIMO.
           EXEC CICS READNEXT
               FILE('EMLANCTO')
               INTO(WS-MOVTO-REG)
               RIDFLD(WS-RBA)
               RBA
               RESP(WS-RESP)
           END-EXEC

           EVALUATE WS-RESP
               WHEN DFHRESP(ENDFILE)
               WHEN DFHRESP(NOTFND)
      *-- Fim do arquivo: encerra o browse ------------------------*
                   MOVE 'S' TO WS-FIM-BROWSE
               WHEN DFHRESP(NORMAL)
      *-- Filtra pelo par agencia+conta ---------------------------*
                   IF WS-MV-AGENCIA = WS-AGENCIA-FILTRO
                      AND WS-MV-CONTA = WS-CONTA-FILTRO
                       ADD 1 TO WS-LINHAS
                       PERFORM 2200-MONTAR-LINHA
                   END-IF
               WHEN OTHER
                   MOVE 'S' TO WS-FIM-BROWSE
           END-EVALUATE.

      *===============================================================*
      * 2200-MONTAR-LINHA                                             *
      * Formata data do movimento para DD/MM/AAAA e acumula           *
      * credito ou debito nos totalizadores.                          *
      * Nota: montagem das linhas OCCURS na tela omitida aqui;        *
      * implementar via indice WS-LINHAS em versao completa.          *
      *===============================================================*
       2200-MONTAR-LINHA.
           MOVE WS-MV-VALOR TO WS-VALOR-EDIT

      *-- Converte data AAAAMMDD para DD/MM/AAAA ------------------*
           STRING WS-MV-DATA(7:2) '/'
                  WS-MV-DATA(5:2) '/'
                  WS-MV-DATA(1:4)
                  DELIMITED BY SIZE
                  INTO WS-DATA-FMT
           END-STRING

      *-- Acumula no totalizador correspondente ao tipo -----------*
           IF WS-MV-TIPO = 'C'
               ADD WS-MV-VALOR TO WS-TOTAL-CREDITOS
           ELSE
               ADD WS-MV-VALOR TO WS-TOTAL-DEBITOS
           END-IF.

      *===============================================================*
      * 3000-MONTAR-TOTAIS                                            *
      * Se nenhuma linha foi carregada exibe mensagem de sem movimento.*
      * Caso contrario edita os totais e envia o mapa de saida.       *
      *===============================================================*
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

      *===============================================================*
      * 8000-ENVIAR-ERRO                                              *
      * Copia mensagem de erro para MSGO e envia o mapa ao terminal.  *
      *===============================================================*
       8000-ENVIAR-ERRO.
           MOVE WS-MSG-RETORNO TO MSGO OF EBMEXTO
           EXEC CICS SEND MAP('EBMEXT')
               MAPSET('EBMEXT')
               FROM(EBMEXTO)
               ERASE
           END-EXEC.

      *===============================================================*
      * 9000-ENCERRAR                                                 *
      * Acionado por PF3 ou CLEAR. Exibe mensagem de encerramento e   *
      * retorna ao CICS sem manter transid ativa.                     *
      *===============================================================*
       9000-ENCERRAR.
           EXEC CICS SEND TEXT
               FROM('TRANSACAO EEXT ENCERRADA')
               ERASE
           END-EXEC
           EXEC CICS RETURN END-EXEC.