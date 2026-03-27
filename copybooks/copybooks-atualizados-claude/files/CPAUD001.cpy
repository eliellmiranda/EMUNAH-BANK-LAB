      *===============================================================*
      * COPYBOOK: CPAUD001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE AUDITORIA                     *
      * REGISTRO: 128 BYTES                                           *
      *                                                               *
      * USADO EM: EBCLLOAD, EBVALI01, EBPOST01, EBSALD01,             *
      *           EBEXTR01, EBCONC01, EBREPR01                       *
      * DATASET : Z77948.EMUNAH.ARQ.AUDIT.SEQ                         *
      * DDNAME  : AUDIT                                               *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar trilha de auditoria no laboratorio               *
      * - Registrar rastreabilidade de todas as operacoes              *
      * - Apoiar conciliacao, troubleshooting e analise de incidentes  *
      *===============================================================*

      *---------------------------------------------------------------*
      * Tipo do evento registrado                                     *
      * INFO = informativo   ERRO = erro tecnico                      *
      * REJT = rejeicao de negocio   OK = sucesso                     *
      * WARN = alerta operacional                                     *
      *---------------------------------------------------------------*
           05 AU-TIPO-EVENTO          PIC X(04).

      *---------------------------------------------------------------*
      * Nome do programa que gerou o registro                         *
      * Ex.: EBCLLOAD, EBPOST01, EBVALI01                             *
      *---------------------------------------------------------------*
           05 AU-PROGRAMA             PIC X(08).

      *---------------------------------------------------------------*
      * Data do evento no formato AAAAMMDD                            *
      *---------------------------------------------------------------*
           05 AU-DATA-EVENTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Hora do evento no formato HHMMSSTH                            *
      * Preenchida com ACCEPT FROM TIME                               *
      *---------------------------------------------------------------*
           05 AU-HORA-EVENTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Codigo resumido do evento                                     *
      * Convencao: <ENT><TIPO><SEQ> ex.: CLIOK001, CNTERR01           *
      *---------------------------------------------------------------*
           05 AU-COD-EVENTO           PIC X(10).

      *---------------------------------------------------------------*
      * Chave principal relacionada ao evento                         *
      * Ex.: id do cliente, chave da conta, nseq do lancamento        *
      *---------------------------------------------------------------*
           05 AU-CHAVE-REF            PIC X(20).

      *---------------------------------------------------------------*
      * Mensagem descritiva do evento                                 *
      *---------------------------------------------------------------*
           05 AU-MENSAGEM             PIC X(60).

      *---------------------------------------------------------------*
      * Complemento livre para contexto adicional                     *
      * Ex.: valor envolvido, RC, status anterior                     *
      *---------------------------------------------------------------*
           05 AU-COMPLEMENTO          PIC X(10).
