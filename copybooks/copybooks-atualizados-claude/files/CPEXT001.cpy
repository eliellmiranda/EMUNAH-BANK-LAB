      *===============================================================*
      * COPYBOOK: CPEXT001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE EXTRATO                       *
      * REGISTRO: 100 BYTES                                           *
      *                                                               *
      * USADO EM: EBEXTR01 (GERACAO DE EXTRATO)                       *
      * DATASET : Z77948.EMUNAH.ARQ.EXTRATO.GDG                       *
      * DDNAME  : EXTRATO                                             *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar a linha de extrato gerada por conta              *
      * - Registrar movimento, valor, saldo apos e canal              *
      * - Cada execucao de EBJEXTR gera uma nova geracao do GDG       *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta                                                *
      * Compativel com CNT-CHAVE e LCT-CHAVE-CONTA                    *
      *---------------------------------------------------------------*
           05 EXT-CHAVE-CONTA.
              10 EXT-AGENCIA          PIC 9(04).
              10 EXT-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Data do movimento no formato AAAAMMDD                         *
      *---------------------------------------------------------------*
           05 EXT-DATA-MOVTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Sequencial do lancamento no dia                               *
      * Permite ordenacao cronologica dentro da mesma data             *
      *---------------------------------------------------------------*
           05 EXT-NSEQ                PIC 9(06).

      *---------------------------------------------------------------*
      * Tipo do movimento                                             *
      * C = Credito   D = Debito                                      *
      *---------------------------------------------------------------*
           05 EXT-TIPO                PIC X(01).

      *---------------------------------------------------------------*
      * Descricao do movimento                                        *
      *---------------------------------------------------------------*
           05 EXT-DESCRICAO           PIC X(30).

      *---------------------------------------------------------------*
      * Valor do movimento                                            *
      * Sinalizado para permitir estornos e ajustes                   *
      *---------------------------------------------------------------*
           05 EXT-VALOR               PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Saldo da conta apos este movimento                            *
      * Sinalizado para refletir posicao real                         *
      *---------------------------------------------------------------*
           05 EXT-SALDO-APOS          PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Canal de origem do movimento                                  *
      * Exemplos: ATM, APP, PIX, CX, INTERNET                        *
      *---------------------------------------------------------------*
           05 EXT-CANAL               PIC X(10).

      *---------------------------------------------------------------*
      * Reserva para evolucao do layout                               *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(07).
