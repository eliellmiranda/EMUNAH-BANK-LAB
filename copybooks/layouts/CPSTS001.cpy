      *================================================================*
      * COPYBOOK: CPSTS001                                             *
      * FINALIDADE:                                                    *
      *   Layout fisico do dataset ARQ.CTL.STATUS — representa a       *
      *   fase corrente do ciclo batch do lab (FLEXCUBE-inspired).     *
      *                                                                *
      * DATASET: Z77948.EMUNAH.ARQ.CTL.STATUS                          *
      * DCB    : RECFM=FB, LRECL=8, 1 unico registro                   *
      *                                                                *
      * VALORES VALIDOS (literais justificados a esquerda, padding     *
      * com espacos a direita ate 8 bytes):                            *
      *                                                                *
      *   'OPEN    '  - Ciclo aberto. Gravado por EBJSOD.              *
      *                 Entrada de transacoes autorizada.              *
      *                                                                *
      *   'EOTI    '  - End Of Transaction Input. Gravado por          *
      *                 EBJCUTF. Janela de entrada fechada; accruals   *
      *                 e snapshot ja podem rodar.                     *
      *                                                                *
      *   'EOFI    '  - End Of Financial Input. Gravado por EBJCUTE.   *
      *                 Janela financeira fechada; so resta gerar      *
      *                 conciliacao, extratos e fechar o dia.          *
      *                                                                *
      *   'CLOSED  '  - Ciclo encerrado. Gravado por EBJEOD (STEP2).   *
      *                 EBJPRECK de D+1 so autoriza novo ciclo se      *
      *                 encontrar este valor OU se o arquivo estiver   *
      *                 vazio (primeira execucao).                     *
      *                                                                *
      * MAQUINA DE ESTADOS (transicoes unicas aceitas):                *
      *   (inicio)  -> OPEN    via EBCTL01 no EBJSOD                   *
      *   OPEN      -> EOTI    via EBCTL01 no EBJCUTF                  *
      *   EOTI      -> EOFI    via EBCTL01 no EBJCUTE                  *
      *   EOFI      -> CLOSED  via EBCTL01 no EBJEOD (CLOSDAY)         *
      *                                                                *
      *   Qualquer outra transicao e rejeitada pelo EBCTL01 com        *
      *   RETURN-CODE=12. EBPCHK01 usa este layout para validar se     *
      *   o conteudo lido bate com um dos PARMs autorizados.           *
      *                                                                *
      * USO:                                                           *
      *   Incluir em WORKING-STORAGE ou na FILE SECTION do programa    *
      *   que le/escreve CTL.STATUS. O nivel 05 permite insercao       *
      *   direta em uma descricao de 01-REG ou em COPY aninhada.       *
      *================================================================*
           05 STS-CODIGO               PIC X(08).
              88 STS-VAZIO             VALUE SPACES.
              88 STS-OPEN              VALUE 'OPEN    '.
              88 STS-EOTI              VALUE 'EOTI    '.
              88 STS-EOFI              VALUE 'EOFI    '.
              88 STS-CLOSED            VALUE 'CLOSED  '.
              88 STS-VALIDO            VALUES ARE
                                       'OPEN    ' 'EOTI    '
                                       'EOFI    ' 'CLOSED  '.