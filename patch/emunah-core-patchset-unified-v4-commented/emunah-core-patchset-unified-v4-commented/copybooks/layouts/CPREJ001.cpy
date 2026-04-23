      *===============================================================*
      * COPYBOOK : CPREJ001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPREJ001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout do registro de rejeito.                 *
      * TAMANHO   : 120 bytes                                      *
      * USADO EM  : Validação, postagem e reprocessamento.         *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
*===============================================================*
* COPYBOOK: CPREJ001                                            *
* FUNCAO  : LAYOUT DE REJEITO PADRONIZADO                       *
* REGISTRO: 120 BYTES                                           *
* DATASET : Z77948.EMUNAH.ARQ.REJEITOS.SEQ                      *
* DDNAME  : REJEITOS                                            *
*===============================================================*
     05 REJ-CHAVE-CONTA.
        10 REJ-AGENCIA          PIC 9(04).
        10 REJ-NUM-CONTA        PIC 9(08).
     05 REJ-DATA-LANCTO         PIC 9(08).
     05 REJ-TIPO-LANCTO         PIC X(01).
     05 REJ-VALOR               PIC S9(11)V99.
     05 REJ-NSEQ-ORIG           PIC 9(06).
     05 REJ-COD-MOTIVO          PIC X(04).
     05 REJ-DESC-MOTIVO         PIC X(32).
     05 REJ-PROGRAMA            PIC X(08).
     05 REJ-DATA-REJEITO        PIC 9(08).
     05 REJ-HORA-REJEITO        PIC 9(08).
     05 FILLER                  PIC X(20).
