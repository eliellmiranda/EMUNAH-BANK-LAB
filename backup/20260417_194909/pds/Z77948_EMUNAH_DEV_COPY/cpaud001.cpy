      *===============================================================*
      * COPYBOOK: CPAUD001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE AUDITORIA                     *
      *                                                               *
      * O QUE ESTE COPYBOOK FAZ:                                      *
      * - Define a estrutura padrao de um registro de auditoria       *
      * - Permite gravar informacoes de rastreabilidade               *
      * - Organiza evento, programa, data, hora, chave e mensagem     *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Padronizar logs batch no laboratorio                        *
      * - Facilitar analise de erros, rejeicoes e eventos             *
      * - Apoiar conciliacao, carga, validacao e postagem             *
      *===============================================================*

      *---------------------------------------------------------------*
      * Tipo do evento registrado                                     *
      * Exemplos: INFO, ERRO, REJT, OK, WARN                          *
      *---------------------------------------------------------------*
           05 AU-TIPO-EVENTO          PIC X(04).

      *---------------------------------------------------------------*
      * Nome curto do programa que gerou a auditoria                  *
      * Ex.: EBCLLOAD, EBPOST01, EBVALI01                             *
      *---------------------------------------------------------------*
           05 AU-PROGRAMA             PIC X(08).

      *---------------------------------------------------------------*
      * Data do evento no formato AAAAMMDD                            *
      *---------------------------------------------------------------*
           05 AU-DATA-EVENTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Hora do evento no formato HHMMSSTH                            *
      * Pode ser preenchida com ACCEPT FROM TIME                      *
      *---------------------------------------------------------------*
           05 AU-HORA-EVENTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Codigo resumido do evento                                     *
      * Ex.: CLIOK001, CNTERR01, MOVREJ01                             *
      *---------------------------------------------------------------*
           05 AU-COD-EVENTO           PIC X(10).

      *---------------------------------------------------------------*
      * Chave principal relacionada ao evento                         *
      * Pode guardar id do cliente, chave da conta ou job correlato   *
      *---------------------------------------------------------------*
           05 AU-CHAVE-REF            PIC X(20).

      *---------------------------------------------------------------*
      * Mensagem descritiva do evento                                 *
      *---------------------------------------------------------------*
           05 AU-MENSAGEM             PIC X(60).

      *---------------------------------------------------------------*
      * Complemento livre para contexto adicional                     *
      *---------------------------------------------------------------*
           05 AU-COMPLEMENTO          PIC X(10).
