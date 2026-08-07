      *===============================================================*
      * COPYBOOK: CPSTS001                                            *
      * FUNCAO  : LAYOUT DE STATUS DO CICLO BATCH                     *
      * REGISTRO: 8 BYTES                                             *
      *===============================================================*
           05 STS-CODIGO               PIC X(08).
              88 STS-VAZIO             VALUE SPACES.
              88 STS-OPEN              VALUE 'OPEN    '.
              88 STS-EOTI              VALUE 'EOTI    '.
              88 STS-EOFI              VALUE 'EOFI    '.
              88 STS-CLOSED            VALUE 'CLOSED  '.
              88 STS-VALIDO            VALUES 'OPEN    ' 'EOTI    '
                                              'EOFI    ' 'CLOSED  '.
