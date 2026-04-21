      *===============================================================*
      * COPYBOOK: CPLCT001                                            *
      * FUNCAO  : LAYOUT DE LANCAMENTO/MOVIMENTO                      *
      *                                                               *
      * O QUE ESTE COPYBOOK FAZ:                                      *
      * - Define a estrutura padrao de um lancamento bancario         *
      * - Centraliza os campos usados nas rotinas batch               *
      * - Permite reutilizacao em validacao, postagem, extrato        *
      *   conciliacao e outros fluxos                                 *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Padronizar o layout dos movimentos do laboratorio           *
      * - Evitar repeticao de definicoes em varios programas COBOL    *
      * - Facilitar manutencao e evolucao do processamento batch      *
      *===============================================================*

      *---------------------------------------------------------------*
      * Agencia da conta associada ao lancamento                      *
      *---------------------------------------------------------------*
           05 LCT-AGENCIA             PIC 9(4).

      *---------------------------------------------------------------*
      * Numero da conta associada ao lancamento                       *
      *---------------------------------------------------------------*
           05 LCT-NUM-CONTA           PIC 9(8).

      *---------------------------------------------------------------*
      * Data do lancamento no formato AAAAMMDD                        *
      *---------------------------------------------------------------*
           05 LCT-DATA                PIC 9(8).

      *---------------------------------------------------------------*
      * Tipo do movimento                                             *
      * Exemplos:                                                     *
      * C = Credito                                                   *
      * D = Debito                                                    *
      *---------------------------------------------------------------*
           05 LCT-TIPO                PIC X(1).

      *---------------------------------------------------------------*
      * Valor do lancamento                                           *
      *---------------------------------------------------------------*
           05 LCT-VALOR               PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Historico ou descricao resumida do movimento                  *
      *---------------------------------------------------------------*
           05 LCT-HISTORICO           PIC X(30).

      *---------------------------------------------------------------*
      * Canal de origem do movimento                                  *
      * Exemplos: ATM, APP, PIX, CX, INTERNET                         *
      *---------------------------------------------------------------*
           05 LCT-CANAL               PIC X(10).

      *---------------------------------------------------------------*
      * Identificador do lote/processamento                           *
      *---------------------------------------------------------------*
           05 LCT-LOTE                PIC 9(6).

      *---------------------------------------------------------------*
      * Identificador sequencial do lancamento no lote                *
      *---------------------------------------------------------------*
           05 LCT-NSEQ                PIC 9(6).

      *---------------------------------------------------------------*
      * Status do lancamento                                          *
      * Exemplos:                                                     *
      * P = Pendente                                                  *
      * V = Validado                                                  *
      * R = Rejeitado                                                 *
      * C = Conciliado                                                *
      *---------------------------------------------------------------*
           05 LCT-STATUS              PIC X(1).

      *---------------------------------------------------------------*
      * Completa o tamanho fisico do registro                         *
      *---------------------------------------------------------------*
           05 LCT-FILLER              PIC X(33).
