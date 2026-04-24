      *===============================================================*
      * COPYBOOK: CPCNT001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE CONTA                         *
      * REGISTRO: 100 BYTES                                           *
      *                                                               *
      * USADO EM: EBCLLOAD (CARGA), EBVALI01 (VALIDACAO),             *
      *           EBPOST01 (POSTAGEM), EBSALD01 (CONSULTA SALDO),     *
      *           EBEXTR01 (EXTRATO)                                  *
      * DATASET : Z77948.EMUNAH.ARQ.CONTA.KSDS                        *
      * DDNAME  : CONTA                                               *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o cadastro de contas no laboratorio              *
      * - Centralizar os campos usados pelos programas batch          *
      * - Permitir leitura, gravacao, postagem e consulta de saldo    *
      * - Evitar repeticao de definicoes em varios programas COBOL    *
      *                                                               *
      * VALORES DE TIPO DE CONTA:                                     *
      *   C = Corrente   P = Poupanca   S = Salario                   *
      *                                                               *
      * VALORES DE STATUS DA CONTA:                                   *
      *   A = Ativa    — movimentacao permitida normalmente           *
      *   I = Inativa  — conta encerrada sem movimentacao             *
      *   B = Bloqueada — debitos suspensos por restricao             *
      *===============================================================*

      *---------------------------------------------------------------*
      * Chave da conta — usada como RECORD KEY no KSDS                *
      * Composta por agencia (4 dig.) + numero da conta (8 dig.)      *
      * Deve ser unica por registro — nao admite duplicidade no KSDS  *
      * Compativel com LCT-AGENCIA/LCT-NUM-CONTA e REJ-CHAVE-CONTA   *
      *---------------------------------------------------------------*
           05 CNT-CHAVE.
              10 CNT-AGENCIA          PIC 9(04).
              10 CNT-NUM-CONTA        PIC 9(08).

      *---------------------------------------------------------------*
      * Identificador do cliente titular da conta                     *
      * Relaciona a conta ao registro em ARQ.CLIENTE.KSDS             *
      * Validado via leitura do KSDS de clientes no EBCLLOAD          *
      *---------------------------------------------------------------*
           05 CNT-ID-CLIENTE          PIC 9(05).

      *---------------------------------------------------------------*
      * Tipo da conta — define regras de movimentacao aplicaveis      *
      * C = Corrente — admite debito, credito e cheque especial       *
      * P = Poupanca — credito com rendimento, debito restrito        *
      * S = Salario  — credito via folha, debito para o titular       *
      *---------------------------------------------------------------*
           05 CNT-TIPO                PIC X(01).

      *---------------------------------------------------------------*
      * Status da conta — controla permissao de movimentacao          *
      * A = Ativa     — todas as operacoes permitidas                 *
      * I = Inativa   — conta encerrada, bloqueada para operacoes     *
      * B = Bloqueada — apenas creditos permitidos, debitos rejeitados *
      * Verificado pelo EBVALI01 antes de aprovar lancamentos          *
      *---------------------------------------------------------------*
           05 CNT-STATUS              PIC X(01).

      *---------------------------------------------------------------*
      * Data de abertura da conta no formato AAAAMMDD                 *
      * Preenchida na carga inicial via EBCLLOAD                      *
      * Ex.: 20230101 = conta aberta em 01 de janeiro de 2023         *
      *---------------------------------------------------------------*
           05 CNT-DATA-ABERTURA       PIC 9(08).

      *---------------------------------------------------------------*
      * Saldo atual da conta em formato DISPLAY                       *
      * Atualizado a cada postagem pelo EBPOST01                      *
      * Lido pelo EBSALD01 para composicao do registro de saldo       *
      * Para calculos internos, mover para WS com PIC S9(13)V99 COMP-3*
      *---------------------------------------------------------------*
           05 CNT-SALDO               PIC 9(11)V99.

      *---------------------------------------------------------------*
      * Limite de credito disponivel (cheque especial)                *
      * Somado ao saldo para calcular posicao disponivel total        *
      * Contas do tipo S (Salario) nao utilizam este campo            *
      *---------------------------------------------------------------*
           05 CNT-LIMITE              PIC 9(09)V99.

      *---------------------------------------------------------------*
      * Reserva para completar o tamanho fisico do registro (100 bytes)*
      * Nao utilizar — reservado para evolucao futura do layout       *
      *---------------------------------------------------------------*
           05 CNT-FILLER              PIC X(49).