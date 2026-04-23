*===============================================================*
      * COPYBOOK: CPLCT001                                            *
      * FUNCAO  : LAYOUT DE LANCAMENTO / MOVIMENTO                    *
      * REGISTRO: 120 BYTES                                           *
      *                                                               *
      * USADO EM: EBVALI01 (VALIDACAO), EBPOST01 (POSTAGEM),          *
      *           EBEXTR01 (EXTRATO), EBREPR01 (REPROCESSAMENTO),     *
      *           EBCONC01 (CONCILIACAO)                              *
      * DATASET : Z77948.EMUNAH.ARQ.ENTRADA.SEQ  (entrada do dia)     *
      *           Z77948.EMUNAH.ARQ.LANCTO.ESDS  (lancamentos validos)*
      * DDNAME  : ENTRADA / VALIDOS                                   *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o layout de lancamento/movimento do laboratorio  *
      * - Reutilizar a mesma estrutura em validacao, postagem,        *
      *   extrato, reprocessamento e conciliacao                      *
      * - Evitar repeticao de definicoes em varios programas COBOL    *
      *                                                               *
      * VALORES DE TIPO DE LANCAMENTO:                                *
      *   C = Credito — aumenta saldo da conta                        *
      *   D = Debito  — diminui saldo da conta                        *
      *                                                               *
      * VALORES DE STATUS DO LANCAMENTO:                              *
      *   P = Pendente   — aguardando validacao                       *
      *   V = Validado   — aprovado pelo EBVALI01                     *
      *   R = Rejeitado  — reprovado, gravado no REJEITO.SEQ          *
      *   C = Conciliado — confirmado pelo EBCONC01                   *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta associada ao lancamento                        *
      * Grupo compativel com CNT-CHAVE (CPCNT001) e REJ-CHAVE-CONTA  *
      * Usado como argumento de leitura no KSDS de contas             *
      *---------------------------------------------------------------*
           05 LCT-CHAVE-CONTA.
              10 LCT-AGENCIA          PIC 9(04).
              10 LCT-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Data do lancamento no formato AAAAMMDD (padrao mainframe)     *
      * Preenchida na carga do arquivo de entrada do dia              *
      * Ex.: 20240315 = 15 de marco de 2024                           *
      *---------------------------------------------------------------*
           05 LCT-DATA                PIC 9(08).

      *---------------------------------------------------------------*
      * Tipo do lancamento                                            *
      * C = Credito — soma ao saldo                                   *
      * D = Debito  — subtrai do saldo, exige validacao de limite     *
      *---------------------------------------------------------------*
           05 LCT-TIPO                PIC X(01).

      *---------------------------------------------------------------*
      * Valor do lancamento em formato DISPLAY sinalizado             *
      * Sinalizado para suportar estornos e ajustes                   *
      * Para calculos internos mover para WS com PIC S9(13)V99 COMP-3 *
      *---------------------------------------------------------------*
           05 LCT-VALOR               PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Historico ou descricao resumida do movimento                  *
      * Gravado na linha de extrato pelo EBEXTR01                     *
      * Ex.: 'PAGAMENTO PIX', 'DEPOSITO ATM', 'TED RECEBIDA'         *
      *---------------------------------------------------------------*
           05 LCT-HISTORICO           PIC X(30).

      *---------------------------------------------------------------*
      * Canal de origem do lancamento                                 *
      * Registrado no extrato e na auditoria para rastreabilidade     *
      * Exemplos: ATM, APP, PIX, CX, INTERNET, TED, DOC              *
      *---------------------------------------------------------------*
           05 LCT-CANAL               PIC X(10).

      *---------------------------------------------------------------*
      * Identificador do lote de processamento                        *
      * Agrupa lancamentos submetidos na mesma execucao do job        *
      * Usado em conciliacao e reprocessamento para isolar o lote     *
      *---------------------------------------------------------------*
           05 LCT-LOTE                PIC 9(06).

      *---------------------------------------------------------------*
      * Sequencial do lancamento dentro do lote                       *
      * Combinado com LCT-LOTE forma identificador unico do registro  *
      * Preservado no REJEITO para rastreabilidade do lancamento orig *
      *---------------------------------------------------------------*
           05 LCT-NSEQ                PIC 9(06).

      *---------------------------------------------------------------*
      * Status atual do lancamento no ciclo de processamento          *
      * P = Pendente  V = Validado  R = Rejeitado  C = Conciliado     *
      * Atualizado a cada etapa pelo programa responsavel             *
      *---------------------------------------------------------------*
           05 LCT-STATUS              PIC X(01).

      *---------------------------------------------------------------*
      * Reserva para completar o tamanho fisico do registro (120 bytes)*
      * Nao utilizar — reservado para evolucao futura do layout       *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(33).