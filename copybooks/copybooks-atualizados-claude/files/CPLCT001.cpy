      *===============================================================*
      * COPYBOOK: CPLCT001                                            *
      * FUNCAO  : LAYOUT DE LANCAMENTO/MOVIMENTO                      *
      * REGISTRO: 120 BYTES                                           *
      *                                                               *
      * USADO EM: EBVALI01 (VALIDACAO), EBPOST01 (POSTAGEM),          *
      *           EBSALD01 (SALDO), EBEXTR01 (EXTRATO),               *
      *           EBCONC01 (CONCILIACAO), EBREPR01 (REPROCESSAMENTO)  *
      * DATASETS: Z77948.EMUNAH.ARQ.ENTRADA.SEQ (ENTRADA)             *
      *           Z77948.EMUNAH.ARQ.LANCTO.ESDS (APROVADOS)           *
      * DDNAMES : ENTRADA, VALIDOS                                    *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o layout dos movimentos do laboratorio           *
      * - Reutilizar em validacao, postagem, extrato e conciliacao    *
      * - Facilitar manutencao e evolucao do processamento batch      *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta associada ao lancamento                        *
      * Formada por agencia (4) + numero da conta (8)                 *
      * Compativel com CNT-CHAVE do copybook CPCNT001                 *
      *---------------------------------------------------------------*
           05 LCT-CHAVE-CONTA.
              10 LCT-AGENCIA          PIC 9(04).
              10 LCT-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Data do lancamento no formato AAAAMMDD                        *
      *---------------------------------------------------------------*
           05 LCT-DATA                PIC 9(08).

      *---------------------------------------------------------------*
      * Tipo do movimento                                             *
      * C = Credito   D = Debito                                      *
      *---------------------------------------------------------------*
           05 LCT-TIPO                PIC X(01).

      *---------------------------------------------------------------*
      * Valor do lancamento                                           *
      * Sinalizado para permitir estornos e ajustes                   *
      *---------------------------------------------------------------*
           05 LCT-VALOR               PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Historico ou descricao resumida do movimento                  *
      *---------------------------------------------------------------*
           05 LCT-HISTORICO           PIC X(30).

      *---------------------------------------------------------------*
      * Canal de origem do movimento                                  *
      * Exemplos: ATM, APP, PIX, CX, INTERNET                        *
      *---------------------------------------------------------------*
           05 LCT-CANAL               PIC X(10).

      *---------------------------------------------------------------*
      * Identificador do lote/processamento                           *
      *---------------------------------------------------------------*
           05 LCT-LOTE                PIC 9(06).

      *---------------------------------------------------------------*
      * Identificador sequencial do lancamento no lote                *
      *---------------------------------------------------------------*
           05 LCT-NSEQ                PIC 9(06).

      *---------------------------------------------------------------*
      * Status do lancamento                                          *
      * P = Pendente   V = Validado   R = Rejeitado   C = Conciliado  *
      *---------------------------------------------------------------*
           05 LCT-STATUS              PIC X(01).

      *---------------------------------------------------------------*
      * Reserva para evolucao do layout                               *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(33).
