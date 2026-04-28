      *===============================================================*
      * COPYBOOK: CPREJ001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE REJEICAO                      *
      * REGISTRO: 156 BYTES (Ajustado para novo Timestamp)            *
      *===============================================================*
           05 REJ-REGISTRO-ORIG        PIC X(120).
           05 REJ-MOTIVO.
              10 REJ-COD-MOTIVO        PIC X(04).
                 88 REJ-MOTIVO-TIPO    VALUE 'TIPO'.
                 88 REJ-MOTIVO-AGEN    VALUE 'AGEN'.
                 88 REJ-MOTIVO-CONT    VALUE 'CONT'.
                 88 REJ-MOTIVO-VALR    VALUE 'VALR'.
                 88 REJ-MOTIVO-DATA    VALUE 'DATA'.
                 88 REJ-MOTIVO-TRNC    VALUE 'TRNC'.
                 88 REJ-MOTIVO-SALD    VALUE 'SALD'.
                 88 REJ-MOTIVO-DUPL    VALUE 'DUPL'.
                 88 REJ-MOTIVO-TRVD    VALUE 'TRVD'.
              10 REJ-TXT-MOTIVO        PIC X(14).
           05 REJ-TIMESTAMP            PIC X(14).
           05 REJ-ORIGEM               PIC X(04).
              88 REJ-ORIGEM-VALI       VALUE 'VALI'.
              88 REJ-ORIGEM-POST       VALUE 'POST'.
              88 REJ-ORIGEM-REPR       VALUE 'REPR'.