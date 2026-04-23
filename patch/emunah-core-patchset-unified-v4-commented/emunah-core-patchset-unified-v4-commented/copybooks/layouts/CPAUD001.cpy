      *===============================================================*
      * COPYBOOK : CPAUD001.cpy                                      *
      * CAMINHO  : copybooks/layouts/CPAUD001.cpy                    *
      *---------------------------------------------------------------*
      * FINALIDADE: Layout padronizado da trilha de auditoria.     *
      * TAMANHO   : 120 bytes                                      *
      * USADO EM  : Programas que escrevem AUDIT.SEQ.              *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este copybook padroniza um layout do laboratorio e evita      *
      * que os programas reescrevam a mesma estrutura em varios       *
      * pontos do codigo. Em um lab didatico, isso ajuda a ligar      *
      * layout, dataset, DDNAME e programa consumidor.                *
      *===============================================================*
*===============================================================*
* COPYBOOK: CPAUD001                                            *
* FUNCAO  : LAYOUT DE AUDITORIA PADRONIZADO                     *
* REGISTRO: 120 BYTES                                           *
* DATASET : Z77948.EMUNAH.ARQ.AUDIT.SEQ                         *
* DDNAME  : AUDIT                                               *
*===============================================================*
     05 AU-TIPO-EVENTO          PIC X(04).
     05 AU-PROGRAMA             PIC X(08).
     05 AU-DATA-EVENTO          PIC 9(08).
     05 AU-HORA-EVENTO          PIC 9(08).
     05 AU-COD-EVENTO           PIC X(10).
     05 AU-CHAVE-REF            PIC X(20).
     05 AU-MENSAGEM             PIC X(50).
     05 AU-COMPLEMENTO          PIC X(12).
