      *===============================================================*
      * COPYBOOK: CPAUD001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE TRILHA DE AUDITORIA BATCH     *
      * REGISTRO: 120 BYTES (Alinhado com FDs dos programas)          *
      * *
      * USADO EM: EBPOST01, EBVALI01, EBCLLOAD, EBEXTR01, EBSNAP01    *
      * DATASET : ELIEL.EMUNAH.ARQ.AUDIT.SEQ                         *
      * DDNAME  : AUDIT                                               *
      * *
      * FINALIDADE:                                                   *
      * - Padronizar a trilha de auditoria de todo o ciclo batch      *
      * - Registrar eventos relevantes para rastreabilidade           *
      * - Permitir acesso individualizado a data e hora do evento     *
      * - Manter compatibilidade com limite fisico de 120 bytes       *
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
