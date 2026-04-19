      *===============================================================*
      * COPYBOOK: CPCNT001                                            *
      * FUNCAO  : LAYOUT DE CONTA                                     *
      * REGISTRO: 100 BYTES                                           *
      *                                                               *
      * USADO EM: EBCLLOAD (CARGA), EBVALI01 (VALIDACAO),             *
      *           EBPOST01 (POSTAGEM), EBSALD01 (SALDO),              *
      *           EBEXTR01 (EXTRATO), EBCONC01 (CONCILIACAO)          *
      * DATASET : Z77948.EMUNAH.ARQ.CONTA.KSDS                        *
      * DDNAME  : CONTA                                               *
      * CHAVE   : CNT-CHAVE (POSICAO 1, TAMANHO 12)                   *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o cadastro de contas no laboratorio              *
      * - Permitir leitura, gravacao, postagem e consulta de saldo    *
      * - Evitar repeticao de definicoes em varios programas COBOL    *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta                                                *
      * Formada por agencia (4) + numero da conta (8)                 *
      * Usada como RECORD KEY no KSDS                                 *
      *---------------------------------------------------------------*
           05 CNT-CHAVE.
              10 CNT-AGENCIA          PIC 9(04).
              10 CNT-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Identificador do cliente titular da conta                     *
      * Relaciona a conta ao cadastro de clientes (CPCLI001)          *
      *---------------------------------------------------------------*
           05 CNT-ID-CLIENTE          PIC 9(05).

      *---------------------------------------------------------------*
      * Tipo da conta                                                 *
      * C = Corrente   P = Poupanca   S = Salario                     *
      *---------------------------------------------------------------*
           05 CNT-TIPO                PIC X(01).

      *---------------------------------------------------------------*
      * Status da conta                                               *
      * A = Ativa   I = Inativa   B = Bloqueada                       *
      *---------------------------------------------------------------*
           05 CNT-STATUS              PIC X(01).

      *---------------------------------------------------------------*
      * Data de abertura da conta no formato AAAAMMDD                 *
      *---------------------------------------------------------------*
           05 CNT-DATA-ABERTURA       PIC 9(08).

      *---------------------------------------------------------------*
      * Saldo atual da conta                                          *
      * Sinalizado para permitir saldo negativo (cheque especial)     *
      *---------------------------------------------------------------*
           05 CNT-SALDO               PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Limite de credito/cheque especial                             *
      * Sinalizado por consistencia com demais campos monetarios      *
      *---------------------------------------------------------------*
           05 CNT-LIMITE              PIC S9(09)V99.

      *---------------------------------------------------------------*
      * Reserva para evolucao do layout                               *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(49).
