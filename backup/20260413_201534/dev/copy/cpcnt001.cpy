      *===============================================================*
      * COPYBOOK: CPCNT001                                            *
      * FUNCAO  : LAYOUT DE CONTA                                     *
      *                                                               *
      * O QUE ESTE COPYBOOK FAZ:                                      *
      * - Define a estrutura padrao de um registro de conta           *
      * - Centraliza os campos usados pelos programas batch           *
      * - Permite reutilizacao do layout em entrada, KSDS e consulta  *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Padronizar o cadastro de contas no laboratorio              *
      * - Permitir leitura, gravacao, postagem e consulta de saldo    *
      * - Evitar repeticao de definicoes em varios programas COBOL    *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta                                                *
      * Formada por agencia + numero da conta                         *
      * Este grupo pode ser usado como RECORD KEY no KSDS             *
      *---------------------------------------------------------------*
           05 CNT-CHAVE.
              10 CNT-AGENCIA          PIC 9(4).
              10 CNT-NUM-CONTA        PIC 9(8).

      *---------------------------------------------------------------*
      * Identificador do cliente titular da conta                     *
      * Relaciona a conta ao cadastro de clientes                     *
      *---------------------------------------------------------------*
           05 CNT-ID-CLIENTE          PIC 9(5).

      *---------------------------------------------------------------*
      * Tipo da conta                                                 *
      * Exemplos:                                                     *
      * C = Corrente                                                  *
      * P = Poupanca                                                  *
      * S = Salario                                                   *
      *---------------------------------------------------------------*
           05 CNT-TIPO                PIC X(1).

      *---------------------------------------------------------------*
      * Status da conta                                               *
      * Exemplos de uso no laboratorio:                               *
      * A = Ativa                                                     *
      * I = Inativa                                                   *
      * B = Bloqueada                                                 *
      *---------------------------------------------------------------*
           05 CNT-STATUS              PIC X(1).

      *---------------------------------------------------------------*
      * Data de abertura da conta no formato AAAAMMDD                 *
      *---------------------------------------------------------------*
           05 CNT-DATA-ABERTURA       PIC 9(8).

      *---------------------------------------------------------------*
      * Saldo atual da conta                                          *
      * Campo usado por programas de postagem e consulta              *
      *---------------------------------------------------------------*
           05 CNT-SALDO               PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Limite de credito/cheque especial                             *
      *---------------------------------------------------------------*
           05 CNT-LIMITE              PIC 9(9)V99.

      *---------------------------------------------------------------*
      * Completa o tamanho fisico do registro                         *
      *---------------------------------------------------------------*
           05 CNT-FILLER              PIC X(49).
