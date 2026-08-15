      *===============================================================*
      * COPYBOOK: CPAUD001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE TRILHA DE AUDITORIA BATCH     *
      * REGISTRO: 128 BYTES (120 campos + 8 FILLER de alinhamento)    *
      * *
      * USADO EM: EBPOST01, EBVALI01, EBCLLOAD, EBEXTR01, EBSNAP01    *
      *           EBAUDDB1, EBSNAP01, EBREPR01                        *
      * DATASET : ELIEL.EMUNAH.ARQ.AUDIT.SEQ                         *
      * DDNAME  : AUDIT / AUDSEQ                                      *
      * *
      * FINALIDADE:                                                   *
      * - Padronizar a trilha de auditoria de todo o ciclo batch      *
      * - Registrar eventos relevantes para rastreabilidade           *
      * - Permitir acesso individualizado a data e hora do evento     *
      * - Manter compatibilidade com limite fisico de 128 bytes       *
      *                                                               *
      * NOTA DE ALINHAMENTO:                                          *
      * Os 8 bytes de FILLER foram movidos para dentro do copybook    *
      * para que qualquer programa que use COPY CPAUD001 receba       *
      * automaticamente o registro de 128 bytes correto.              *
      * Antes estavam declarados individualmente em EBVALI01 e        *
      * EBPOST01 como "05 FILLER PIC X(8)" apos o COPY — mantidos    *
      * la por compatibilidade (redundantes mas inofensivos).         *
      *===============================================================*

      *---------------------------------------------------------------*
      * Tipo do evento registrado na trilha de auditoria              *
      *---------------------------------------------------------------*
           05 AU-TIPO-EVENTO           PIC X(04).

      *---------------------------------------------------------------*
      * Nome do programa que gerou o registro                         *
      *---------------------------------------------------------------*
           05 AU-PROGRAMA              PIC X(08).

      *---------------------------------------------------------------*
      * Timestamp unificado composto por Data e Hora                  *
      * Permite mover o bloco completo ou campos individuais          *
      *---------------------------------------------------------------*
           05 AU-TIMESTAMP.
              10 AU-DATA-EVENTO          PIC 9(08).
              10 AU-HORA-EVENTO          PIC 9(06).

      *---------------------------------------------------------------*
      * Codigo resumido do evento auditado                            *
      *---------------------------------------------------------------*
           05 AU-COD-EVENTO            PIC X(10).

      *---------------------------------------------------------------*
      * Chave principal relacionada ao evento (Ex: Ag+Conta)          *
      *---------------------------------------------------------------*
           05 AU-CHAVE-REF             PIC X(20).

      *---------------------------------------------------------------*
      * Mensagem descritiva (Tamanho ajustado para total de 120 bytes)*
      *---------------------------------------------------------------*
           05 AU-MENSAGEM              PIC X(54).

      *---------------------------------------------------------------*
      * Complemento livre para contexto adicional (RC, SQLCODE, etc)  *
      *---------------------------------------------------------------*
           05 AU-COMPLEMENTO           PIC X(10).

      *---------------------------------------------------------------*
      * FILLER de alinhamento — completa 128 bytes fisicos            *
      * (LRECL=128 em ELIEL.EMUNAH.ARQ.AUDIT.SEQ)                    *
      *---------------------------------------------------------------*
           05 FILLER                   PIC X(08).
