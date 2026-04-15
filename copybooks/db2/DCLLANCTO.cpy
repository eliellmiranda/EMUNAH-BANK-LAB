      *===============================================================*
      * COPYBOOK: DCLLANCTO                                           *
      * FUNCAO  : DCLGEN DA TABELA DB2 TB_LANCAMENTO                 *
      *                                                               *
      * TABELA   : EMUNAH.TB_LANCAMENTO                              *
      * OWNER    : EMUNAH                                             *
      *                                                               *
      * ESTE COPYBOOK SIMULA A SAIDA DO UTILITARIO DCLGEN DO DB2     *
      * PARA USO EM PROGRAMAS QUE ACESSAM A TABELA DE LANCAMENTOS    *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA HOST VARIABLES - TABELA TB_LANCAMENTO                    *
      *---------------------------------------------------------------*
       01  DCLTB-LANCAMENTO.
      *    ID_LANCAMENTO     INTEGER NOT NULL GENERATED ALWAYS
           05 LCT-ID-LANCAMENTO      PIC S9(9) COMP.
      *    AGENCIA           SMALLINT NOT NULL
           05 LCT-AGENCIA            PIC S9(4) COMP.
      *    NUM_CONTA         INTEGER NOT NULL
           05 LCT-NUM-CONTA          PIC S9(9) COMP.
      *    DATA_LANCAMENTO   DATE NOT NULL
           05 LCT-DATA               PIC X(10).
      *    TIPO_MOVTO        CHAR(1) NOT NULL
           05 LCT-TIPO               PIC X(1).
      *    VALOR             DECIMAL(13,2) NOT NULL
           05 LCT-VALOR              PIC S9(11)V99 COMP-3.
      *    HISTORICO         VARCHAR(30)
           05 LCT-HISTORICO.
              49 LCT-HISTORICO-LEN   PIC S9(4) COMP.
              49 LCT-HISTORICO-TEXT  PIC X(30).
      *    CANAL             CHAR(10)
           05 LCT-CANAL              PIC X(10).
      *    NUM_LOTE          INTEGER
           05 LCT-LOTE               PIC S9(9) COMP.
      *    NSEQ_LOTE         INTEGER
           05 LCT-NSEQ               PIC S9(9) COMP.
      *    STATUS            CHAR(1) NOT NULL DEFAULT 'P'
           05 LCT-STATUS             PIC X(1).
      *    TIMESTAMP_PROC    TIMESTAMP
           05 LCT-TIMESTAMP          PIC X(26).

      *---------------------------------------------------------------*
      * INDICATOR VARIABLES                                           *
      *---------------------------------------------------------------*
       01  DCLIND-LANCAMENTO.
           05 IND-HISTORICO           PIC S9(4) COMP.
           05 IND-CANAL               PIC S9(4) COMP.
           05 IND-LOTE                PIC S9(4) COMP.
           05 IND-NSEQ                PIC S9(4) COMP.
           05 IND-TIMESTAMP           PIC S9(4) COMP.
