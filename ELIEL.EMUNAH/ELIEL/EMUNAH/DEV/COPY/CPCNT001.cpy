      *===============================================================*
      * COPYBOOK: CPCNT001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE CONTA                         *
      * REGISTRO: 100 BYTES                                           *
      *===============================================================*
           05 CNT-CHAVE.
              10 CNT-AGENCIA           PIC 9(04).
              10 CNT-NUM-CONTA         PIC 9(08).
           05 CNT-ID-CLIENTE           PIC 9(05).
           05 CNT-TIPO                 PIC X(01).
           05 CNT-STATUS               PIC X(01).
           05 CNT-DATA-ABERTURA        PIC 9(08).
           05 CNT-SALDO                PIC S9(11)V99.
           05 CNT-LIMITE               PIC 9(09)V99.
           05 FILLER                   PIC X(49).
