      *===============================================================*
      * COPYBOOK: CPREJ001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE REJEITO                       *
      * REGISTRO: 120 BYTES                                           *
      *                                                               *
      * USADO EM: EBVALI01 (VALIDACAO), EBPOST01 (POSTAGEM),          *
      *           EBREPR01 (REPROCESSAMENTO)                          *
      * DATASET : Z77948.EMUNAH.ARQ.REJEITO.SEQ                       *
      * DDNAME  : REJEITO                                             *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o registro de lancamentos rejeitados              *
      * - Preservar dados do lancamento original para diagnostico     *
      * - Registrar motivo, programa e momento da rejeicao            *
      * - Alimentar reprocessamento e analise de incidentes            *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta do lancamento rejeitado                        *
      * Compativel com CNT-CHAVE e LCT-CHAVE-CONTA                    *
      *---------------------------------------------------------------*
           05 REJ-CHAVE-CONTA.
              10 REJ-AGENCIA          PIC 9(04).
              10 REJ-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Data do lancamento original no formato AAAAMMDD               *
      *---------------------------------------------------------------*
           05 REJ-DATA-LANCTO         PIC 9(08).

      *---------------------------------------------------------------*
      * Tipo do lancamento original                                   *
      * C = Credito   D = Debito                                      *
      *---------------------------------------------------------------*
           05 REJ-TIPO-LANCTO         PIC X(01).

      *---------------------------------------------------------------*
      * Valor do lancamento original                                  *
      *---------------------------------------------------------------*
           05 REJ-VALOR               PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Sequencial original do lancamento no lote                     *
      *---------------------------------------------------------------*
           05 REJ-NSEQ-ORIG           PIC 9(06).

      *---------------------------------------------------------------*
      * Codigo do motivo de rejeicao                                  *
      * Ex.: R001 = conta inexistente, R002 = saldo insuficiente      *
      *      R003 = conta bloqueada, R004 = valor invalido            *
      *      R005 = layout invalido, R006 = duplicidade               *
      *---------------------------------------------------------------*
           05 REJ-COD-MOTIVO          PIC X(04).

      *---------------------------------------------------------------*
      * Descricao do motivo de rejeicao                               *
      *---------------------------------------------------------------*
           05 REJ-DESC-MOTIVO         PIC X(40).

      *---------------------------------------------------------------*
      * Programa que gerou a rejeicao                                 *
      *---------------------------------------------------------------*
           05 REJ-PROGRAMA            PIC X(08).

      *---------------------------------------------------------------*
      * Data da rejeicao no formato AAAAMMDD                          *
      *---------------------------------------------------------------*
           05 REJ-DATA-REJEITO        PIC 9(08).

      *---------------------------------------------------------------*
      * Hora da rejeicao no formato HHMMSSTH                          *
      *---------------------------------------------------------------*
           05 REJ-HORA-REJEITO        PIC 9(08).

      *---------------------------------------------------------------*
      * Reserva para evolucao do layout                               *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(12).
