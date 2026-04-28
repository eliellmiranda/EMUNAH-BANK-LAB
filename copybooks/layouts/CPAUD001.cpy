      *===============================================================*
      * COPYBOOK: CPAUD001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE AUDITORIA                     *
      * REGISTRO: 120 BYTES (Alinhado com as FDs dos programas)       *
      *===============================================================*
           05 AU-TIPO-EVENTO           PIC X(04).
           05 AU-PROGRAMA              PIC X(08).
           05 AU-TIMESTAMP             PIC X(14).
           05 AU-COD-EVENTO            PIC X(10).
           05 AU-CHAVE-REF             PIC X(20).
           05 AU-MENSAGEM              PIC X(54).
           05 AU-COMPLEMENTO           PIC X(10).