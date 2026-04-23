      *===============================================================*
      * COPYBOOK : CPSNP001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPSNP001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout do registro de snapshot diário de saldo.*
      * TAMANHO   : 120 bytes                                      *
      * USADO EM  : EBSNAP01, EBCONC01, EBJEOD01.                  *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
      *===============================================================*
      * COPYBOOK: CPSNP001                                            *
      * FUNCAO  : LAYOUT DO SNAPSHOT DE SALDO                         *
      * REGISTRO: 120 BYTES                                           *
      * DATASET : Z77948.EMUNAH.ARQ.SALDO.GDG                         *
      * DDNAME  : SALDOIN / SALDOUT                                   *
      *===============================================================*
           05 SNP-AGENCIA              PIC 9(04).
           05 SNP-NUM-CONTA            PIC 9(08).
           05 SNP-SALDO                PIC S9(11)V99.
           05 SNP-DATA                 PIC 9(08).
           05 FILLER                   PIC X(87).
