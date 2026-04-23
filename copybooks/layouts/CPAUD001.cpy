*===============================================================*
      * COPYBOOK: CPAUD001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE AUDITORIA                     *
      * REGISTRO: 120 BYTES                                           *
      *                                                               *
      * USADO EM: EBPOST01 (POSTAGEM), EBVALI01 (VALIDACAO),          *
      *           EBCLLOAD (CARGA), EBEXTR01 (EXTRATO)                *
      * DATASET : Z77948.EMUNAH.ARQ.AUDIT.SEQ                         *
      * DDNAME  : AUDIT                                               *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o registro de trilha de auditoria batch          *
      * - Registrar qualquer evento relevante do processamento         *
      * - Organizar evento, programa, data, hora, chave e mensagem    *
      * - Alimentar analise de erros, rejeicoes e rastreabilidade     *
      *                                                               *
      * TIPOS DE EVENTO SUPORTADOS:                                   *
      *   INFO = Informativo (ex: inicio/fim de processamento)        *
      *   ERRO = Erro tecnico ou funcional                            *
      *   REJT = Rejeicao de lancamento ou registro                   *
      *   WARN = Alerta que nao impede o processamento                *
      *   OK   = Conclusao bem-sucedida de operacao                   *
      *===============================================================*

      *---------------------------------------------------------------*
      * Tipo do evento registrado na trilha de auditoria              *
      * Valores aceitos: INFO, ERRO, REJT, WARN, OK                   *
      * Preenchimento obrigatorio — nao deixar em branco              *
      *---------------------------------------------------------------*
           05 AU-TIPO-EVENTO          PIC X(04).

      *---------------------------------------------------------------*
      * Nome do programa que gerou o registro de auditoria            *
      * Deve conter o nome exato do PROGRAM-ID                        *
      * Ex.: EBPOST01, EBVALI01, EBCLLOAD, EBEXTR01                  *
      *---------------------------------------------------------------*
           05 AU-PROGRAMA             PIC X(08).

      *---------------------------------------------------------------*
      * Data do evento no formato AAAAMMDD (padrão mainframe batch)   *
      * Preenchido via: MOVE FUNCTION CURRENT-DATE(1:8) TO AU-DATA    *
      * ou via ACCEPT WS-DATA FROM DATE YYYYMMDD                      *
      *---------------------------------------------------------------*
           05 AU-DATA-EVENTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Hora do evento no formato HHMMSSTH                            *
      * Preenchido via: ACCEPT AU-HORA-EVENTO FROM TIME               *
      * TH = decimos de segundo (centesimal)                          *
      *---------------------------------------------------------------*
           05 AU-HORA-EVENTO          PIC 9(08).

      *---------------------------------------------------------------*
      * Codigo resumido do evento auditado                            *
      * Deve ser unico e descritivo por modulo                        *
      * Ex.: CLIOK001 = cliente carregado com sucesso                 *
      *      CNTERR01 = conta nao encontrada                          *
      *      MOVREJ01 = lancamento rejeitado por saldo insuficiente   *
      *      AUDINI01 = inicio de processamento registrado            *
      *---------------------------------------------------------------*
           05 AU-COD-EVENTO           PIC X(10).

      *---------------------------------------------------------------*
      * Chave principal relacionada ao evento auditado                *
      * Uso flexivel por programa:                                    *
      * - Carga de cliente: ID do cliente (ex: 00042)                *
      * - Postagem: agencia+conta (ex: 00010000001234)                *
      * - Validacao: numero sequencial do lancamento no lote          *
      * - Job: nome do job ou step correlato                          *
      *---------------------------------------------------------------*
           05 AU-CHAVE-REF            PIC X(20).

      *---------------------------------------------------------------*
      * Mensagem descritiva do evento auditado                        *
      * Deve ser clara e objetiva para facilitar diagnostico          *
      * Ex.: 'CLIENTE 00042 CARREGADO COM SUCESSO'                   *
      *      'LANCAMENTO REJEITADO: CONTA BLOQUEADA'                  *
      *---------------------------------------------------------------*
           05 AU-MENSAGEM             PIC X(60).

      *---------------------------------------------------------------*
      * Complemento livre para contexto adicional do evento           *
      * Uso opcional — pode conter codigo de retorno, RC, SQLCODE     *
      * ou qualquer informacao tecnica complementar                   *
      * Ex.: 'RC=0008', 'SQL=-803', 'STS=B'                          *
      *---------------------------------------------------------------*
           05 AU-COMPLEMENTO          PIC X(10).