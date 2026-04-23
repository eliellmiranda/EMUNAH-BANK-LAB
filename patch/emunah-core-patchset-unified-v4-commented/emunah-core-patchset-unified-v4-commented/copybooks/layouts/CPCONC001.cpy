      *===============================================================*
      * COPYBOOK : CPCONC001.cpy                                     *
      * CAMINHO  : copybooks/layouts/CPCONC001.cpy                   *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout estruturado de saída de CONCIL.SEQ.     *
      * TAMANHO   : 132 bytes                                      *
      * USADO EM  : EBCONC01 e leitura do fechamento.              *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
      *===============================================================*
      * COPYBOOK: CPCONC001                                           *
      * FUNCAO  : LAYOUT ESTRUTURADO DA CONCILIACAO                   *
      * REGISTRO: 132 BYTES                                           *
      * DATASET : Z77948.EMUNAH.ARQ.CONCIL.SEQ                        *
      * DDNAME  : CONCOUT / CONCIN                                    *
      *===============================================================*
      *  1-3   TIPO-REG   H11/D11..D34/R11..R31/T98/T99              *
      *  4     FILLER                                                 *
      *  5-54  DESCRICAO                                               *
      * 55     FILLER                                                 *
      * 56-70 VALOR   (-Z(10)9,99)                                     *
      * 71-75 FILLER                                                 *
      * 76-125 STATUS                                                 *
      * 126-132 FILLER                                                *
      *===============================================================*
           05 CC-TIPO-REG              PIC X(03).
           05 FILLER                   PIC X(01).
           05 CC-DESCRICAO             PIC X(50).
           05 FILLER                   PIC X(01).
           05 CC-VALOR                 PIC -Z(10)9,99.
           05 FILLER                   PIC X(05).
           05 CC-STATUS                PIC X(50).
           05 FILLER                   PIC X(07).
