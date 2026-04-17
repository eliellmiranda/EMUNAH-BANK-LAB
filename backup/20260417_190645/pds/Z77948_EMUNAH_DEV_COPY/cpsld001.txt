      *===============================================================*
      * COPYBOOK: CPSLD001                                            *
      * FUNCAO  : LAYOUT DE CONSULTA/SAIDA DE SALDO                   *
      *                                                               *
      * O QUE ESTE COPYBOOK FAZ:                                      *
      * - Define a estrutura padrao para registros de saldo           *
      * - Permite reutilizacao em consultas, relatorios e conferencias*
      * - Centraliza os campos principais de identificacao da conta   *
      *   e do saldo consultado                                       *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Padronizar arquivos de consulta de saldo no laboratorio     *
      * - Evitar repeticao de layout em varios programas COBOL        *
      * - Facilitar integracao entre leitura, consulta e saida        *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta                                                *
      * Formada por agencia + numero da conta                         *
      *---------------------------------------------------------------*
           05 SLD-CHAVE.
              10 SLD-AGENCIA          PIC 9(4).
              10 SLD-NUM-CONTA        PIC 9(8).

      *---------------------------------------------------------------*
      * Identificador do cliente titular                              *
      *---------------------------------------------------------------*
           05 SLD-ID-CLIENTE          PIC 9(5).

      *---------------------------------------------------------------*
      * Tipo da conta                                                 *
      * Exemplos:                                                     *
      * C = Corrente                                                  *
      * P = Poupanca                                                  *
      * S = Salario                                                   *
      *---------------------------------------------------------------*
           05 SLD-TIPO-CONTA          PIC X(1).

      *---------------------------------------------------------------*
      * Status da conta                                               *
      * Exemplos:                                                     *
      * A = Ativa                                                     *
      * I = Inativa                                                   *
      * B = Bloqueada                                                 *
      *---------------------------------------------------------------*
           05 SLD-STATUS              PIC X(1).

      *---------------------------------------------------------------*
      * Data da consulta no formato AAAAMMDD                          *
      *---------------------------------------------------------------*
           05 SLD-DATA-CONSULTA       PIC 9(8).

      *---------------------------------------------------------------*
      * Saldo atual da conta                                          *
      *---------------------------------------------------------------*
           05 SLD-SALDO-ATUAL         PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Limite disponivel/registrado                                  *
      *---------------------------------------------------------------*
           05 SLD-LIMITE              PIC 9(9)V99.

      *---------------------------------------------------------------*
      * Saldo total considerado com limite                            *
      *---------------------------------------------------------------*
           05 SLD-SALDO-DISPONIVEL    PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Completa o tamanho fisico do registro                         *
      *---------------------------------------------------------------*
           05 SLD-FILLER              PIC X(36).
