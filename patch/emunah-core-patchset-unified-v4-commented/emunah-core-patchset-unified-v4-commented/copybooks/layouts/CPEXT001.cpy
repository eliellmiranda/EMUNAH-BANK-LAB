      *===============================================================*
      * COPYBOOK : CPEXT001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPEXT001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout da linha de extrato.                    *
      * TAMANHO   : 132 bytes                                      *
      * USADO EM  : EBEXTR01.                                      *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
*===============================================================*
* COPYBOOK: CPEXT001                                            *
* FUNCAO  : LAYOUT DE EXTRATO                                   *
* REGISTRO: 132 BYTES                                           *
* DATASET : Z77948.EMUNAH.ARQ.EXTRATO.GDG                       *
* DDNAME  : EXTROUT                                             *
*===============================================================*
     05 EXT-CHAVE-CONTA.
        10 EXT-AGENCIA          PIC 9(04).
        10 EXT-NUM-CONTA        PIC 9(08).
     05 EXT-DATA-MOVTO          PIC 9(08).
     05 EXT-NSEQ                PIC 9(06).
     05 EXT-TIPO                PIC X(01).
     05 EXT-DESCRICAO           PIC X(30).
     05 EXT-VALOR               PIC S9(11)V99.
     05 EXT-SALDO-POSICAO       PIC S9(11)V99.
     05 EXT-CANAL               PIC X(10).
     05 FILLER                  PIC X(39).
