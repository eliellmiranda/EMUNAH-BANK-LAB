      *===============================================================*
      * COPYBOOK: EBMEXT                                              *
      * FUNCAO  : MAPA BMS - TELA DE CONSULTA DE EXTRATO             *
      * TRANSACAO CICS: EEXT                                          *
      * PROGRAMA ASSOCIADO: EBCSEXT                                   *
      *                                                               *
      * ESTE COPYBOOK SIMULA O LAYOUT GERADO PELO BMS ASSEMBLER      *
      * (Basic Mapping Support) para a tela de consulta de extrato.   *
      * Em producao este arquivo seria gerado automaticamente pelo    *
      * macro DFHMSD/DFHMDI/DFHMDF durante a montagem do mapset.     *
      *                                                               *
      * CONVENCAO DE SUFIXOS (padrao BMS gerado pelo Assembler):      *
      *   xxxxxL = length field    : comprimento dos dados digitados  *
      *            PIC S9(4) COMP  (halfword binario)                 *
      *   xxxxxF = flag/attribute  : atributos do campo na tela       *
      *            PIC X           (1 byte de atributo)               *
      *   xxxxxA = attribute byte  : alias do flag via REDEFINES      *
      *   xxxxxI = input data      : conteudo digitado pelo operador  *
      *            PIC X(n)        (n = tamanho definido no DFHMDF)   *
      *   xxxxxO = output data     : conteudo a ser exibido na tela   *
      *            PIC X(n)                                           *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA DE ENTRADA (EBMEXTI) - dados recebidos via RECEIVE MAP   *
      * O programa popula esta area apos EXEC CICS RECEIVE MAP        *
      *---------------------------------------------------------------*
       01  EBMEXTI.
      *-- 12 bytes de controle interno BMS (nao usar diretamente) --*
           05 FILLER                  PIC X(12).

      *-- Campo AGENCIA: agencia digitada pelo operador (4 digitos) -*
           05 AGENCIAL                PIC S9(4) COMP.    *> comprimento
           05 AGENCIAF                PIC X.             *> atributo
           05 FILLER REDEFINES AGENCIAF.
              10 AGENCIAA             PIC X.             *> alias attr
           05 AGENCIAI                PIC X(4).          *> dado input

      *-- Campo CONTA: numero de conta (8 digitos) ----------------*
           05 CONTAL                  PIC S9(4) COMP.    *> comprimento
           05 CONTAF                  PIC X.             *> atributo
           05 FILLER REDEFINES CONTAF.
              10 CONTAA               PIC X.             *> alias attr
           05 CONTAI                  PIC X(8).          *> dado input

      *---------------------------------------------------------------*
      * AREA DE SAIDA (EBMEXTO) - dados enviados via SEND MAP         *
      * O programa preenche esta area antes de EXEC CICS SEND MAP     *
      *---------------------------------------------------------------*
       01  EBMEXTO.
      *-- 12 bytes de controle interno BMS -------------------------*
           05 FILLER                  PIC X(12).

      *-- Eco da agencia e conta consultadas na cabecalho da tela --*
           05 AGENCIAO                PIC X(4).
           05 CONTAO                  PIC X(8).

      *-- Linhas de extrato: ate 15 movimentos por pagina ----------*
      *   DATAO      : data do movimento formato DD/MM/AAAA (10)    *
      *   TIPOO      : tipo 'C'=credito / 'D'=debito (1)            *
      *   VALORO     : valor editado com mascara (16)               *
      *   HISTORICOO : descricao do movimento (30)                  *
      *   CANALO     : canal de origem: AGENCIA/INTERNET/APP/etc(10)*
           05 LINHAS-EXTRATO OCCURS 15 TIMES.
              10 DATAO                PIC X(10).
              10 TIPOO                PIC X(1).
              10 VALORO               PIC X(16).
              10 HISTORICOO           PIC X(30).
              10 CANALO               PIC X(10).

      *-- Totais do extrato exibido (rodape) -----------------------*
      *   TOTALCREDO : soma dos creditos das linhas exibidas         *
      *   TOTALDEBO  : soma dos debitos das linhas exibidas          *
           05 TOTALCREDO              PIC X(16).
           05 TOTALDEBO               PIC X(16).

      *-- Mensagem de retorno ao operador --------------------------*
      *   Ex: 'EXTRATO CONSULTADO COM SUCESSO'                       *
      *       'NENHUM MOVIMENTO ENCONTRADO'                          *
      *       'INFORME AGENCIA E CONTA'                              *
           05 MSGO                    PIC X(50).
