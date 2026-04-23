      *===============================================================*
      * COPYBOOK : CPSLD001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPSLD001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout auxiliar de saldo/consulta compatível com o modelo atual do lab.*
      * TAMANHO   : 120 bytes                                      *
      * USADO EM  : Consulta, snapshot e conferências.             *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
*===============================================================*
* COPYBOOK: CPSLD001                                            *
* FUNCAO  : LAYOUT DE POSICAO DE SALDO / SNAPSHOT               *
* REGISTRO: 120 BYTES                                           *
* DATASET : Z77948.EMUNAH.ARQ.SALDO.GDG                         *
* DDNAME  : SALDOIN / SALDOUT                                   *
*===============================================================*
     05 SLD-AGENCIA             PIC 9(04).
     05 SLD-NUM-CONTA           PIC 9(08).
     05 SLD-SALDO               PIC S9(11)V99.
     05 SLD-DATA                PIC 9(08).
     05 FILLER                  PIC X(87).
