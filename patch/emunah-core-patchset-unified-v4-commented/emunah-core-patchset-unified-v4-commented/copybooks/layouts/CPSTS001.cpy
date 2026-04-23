      *===============================================================*
      * COPYBOOK : CPSTS001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPSTS001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout físico de CTL.STATUS.                   *
      * TAMANHO   : 8 bytes                                        *
      * USADO EM  : EBCTL01, EBPCHK01 e JCLs de estado.            *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
      *===============================================================*
      * COPYBOOK: CPSTS001                                            *
      * FUNCAO  : LAYOUT DO CTL.STATUS                                *
      * REGISTRO: 8 BYTES                                             *
      *                                                               *
      * VALORES VALIDOS:                                              *
      *   OPEN    EOTI    EOFI    CLOSED                              *
      *===============================================================*
           05 STS-CODIGO               PIC X(08).
              88 STS-VAZIO             VALUE SPACES.
              88 STS-OPEN              VALUE 'OPEN    '.
              88 STS-EOTI              VALUE 'EOTI    '.
              88 STS-EOFI              VALUE 'EOFI    '.
              88 STS-CLOSED            VALUE 'CLOSED  '.
