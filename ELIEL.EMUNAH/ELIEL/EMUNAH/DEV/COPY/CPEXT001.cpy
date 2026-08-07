      *===============================================================*
      * COPYBOOK: CPEXT001                                            *
      * FUNCAO  : LAYOUT DE EXTRATO BANCARIO                          *
      * REGISTRO: 132 BYTES                                           *
      *===============================================================*
           05 EXT-TIPO-REG             PIC X(01).
           05 EXT-AGENCIA              PIC X(04).
           05 EXT-NUM-CONTA            PIC X(08).
           05 EXT-DATA-MOVTO           PIC X(08).
           05 EXT-NSEQ                 PIC X(06).
           05 EXT-TIPO                 PIC X(01).
           05 EXT-DESCRICAO            PIC X(30).
           05 EXT-VALOR                PIC S9(11)V99 SIGN LEADING.
           05 EXT-SALDO-POSICAO        PIC S9(11)V99 SIGN LEADING.
           05 EXT-CANAL                PIC X(10).
           05 FILLER                   PIC X(38).
