      *===============================================================*
      * COPYBOOK: CPSLD001                                            *
      * FUNCAO  : LAYOUT DE CONSULTA/SAIDA DE SALDO                   *
      * REGISTRO: 100 BYTES                                           *
      *                                                               *
      * USADO EM: EBSALD01 (CONSOLIDACAO), EBCONC01 (CONCILIACAO),    *
      *           EBEXTR01 (EXTRATO)                                  *
      * DATASET : Z77948.EMUNAH.ARQ.SALDO.KSDS                        *
      * DDNAME  : SALDO                                               *
      * CHAVE   : SLD-CHAVE (POSICAO 1, TAMANHO 12)                   *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar registros de saldo no laboratorio                *
      * - Reutilizar em consultas, relatorios e conferencias          *
      * - Facilitar integracao entre consolidacao, extrato e saida    *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta                                                *
      * Formada por agencia (4) + numero da conta (8)                 *
      * Compativel com CNT-CHAVE do copybook CPCNT001                 *
      *---------------------------------------------------------------*
           05 SLD-CHAVE.
              10 SLD-AGENCIA          PIC 9(04).
              10 SLD-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Identificador do cliente titular                              *
      *---------------------------------------------------------------*
           05 SLD-ID-CLIENTE          PIC 9(05).

      *---------------------------------------------------------------*
      * Tipo da conta                                                 *
      * C = Corrente   P = Poupanca   S = Salario                     *
      *---------------------------------------------------------------*
           05 SLD-TIPO-CONTA          PIC X(01).

      *---------------------------------------------------------------*
      * Status da conta                                               *
      * A = Ativa   I = Inativa   B = Bloqueada                       *
      *---------------------------------------------------------------*
           05 SLD-STATUS              PIC X(01).

      *---------------------------------------------------------------*
      * Data da consulta/posicao no formato AAAAMMDD                  *
      *---------------------------------------------------------------*
           05 SLD-DATA-CONSULTA       PIC 9(08).

      *---------------------------------------------------------------*
      * Saldo atual da conta                                          *
      * Sinalizado para permitir saldo negativo (cheque especial)     *
      *---------------------------------------------------------------*
           05 SLD-SALDO-ATUAL         PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Limite de credito disponivel                                  *
      * Sinalizado por consistencia com demais campos monetarios      *
      *---------------------------------------------------------------*
           05 SLD-LIMITE              PIC S9(09)V99.

      *---------------------------------------------------------------*
      * Saldo total disponivel (saldo + limite)                       *
      * Sinalizado para refletir posicao real da conta                *
      *---------------------------------------------------------------*
           05 SLD-SALDO-DISPONIVEL    PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Reserva para evolucao do layout                               *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(36).
