      *===============================================================*
      * COPYBOOK : CPLCT001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPLCT001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout de lançamento/movimento do laboratório. *
      * TAMANHO   : 120 bytes                                      *
      * USADO EM  : Validação, postagem, extrato, reprocessamento e conciliação.*
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
*===============================================================*
* COPYBOOK: CPLCT001                                            *
* FUNCAO  : LAYOUT DE LANCAMENTO / MOVIMENTO                    *
* REGISTRO: 120 BYTES                                           *
* DATASETS: ENTRADA.SEQ / LANCTO.ESDS / REPR.LANCTO.SEQ         *
*===============================================================*
     05 LCT-CHAVE-CONTA.
        10 LCT-AGENCIA          PIC 9(04).
        10 LCT-NUM-CONTA        PIC 9(08).
     05 LCT-DATA                PIC 9(08).
     05 LCT-TIPO                PIC X(01).
     05 LCT-VALOR               PIC S9(11)V99.
     05 LCT-HISTORICO           PIC X(30).
     05 LCT-CANAL               PIC X(10).
     05 LCT-LOTE                PIC 9(06).
     05 LCT-NSEQ                PIC 9(06).
     05 LCT-STATUS              PIC X(01).
     05 FILLER                  PIC X(33).
