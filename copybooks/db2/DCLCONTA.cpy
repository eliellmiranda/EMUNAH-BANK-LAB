      *===============================================================*
      * COPYBOOK: DCLCONTA                                            *
      * FUNCAO  : DCLGEN DA TABELA DB2 TB_CONTA                      *
      *                                                               *
      * TABELA   : EMUNAH.TB_CONTA                                   *
      * OWNER    : EMUNAH                                             *
      *                                                               *
      * ESTE COPYBOOK SIMULA A SAIDA DO UTILITARIO DCLGEN DO DB2     *
      * PARA USO EM PROGRAMAS QUE ACESSAM A TABELA DE CONTAS         *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA HOST VARIABLES - TABELA TB_CONTA                         *
      *---------------------------------------------------------------*
       01  DCLTB-CONTA.
      *    AGENCIA           SMALLINT NOT NULL
           05 CNT-AGENCIA            PIC S9(4) COMP.
      *    NUM_CONTA         INTEGER NOT NULL
           05 CNT-NUM-CONTA          PIC S9(9) COMP.
      *    ID_CLIENTE        INTEGER NOT NULL (FK)
           05 CNT-ID-CLIENTE         PIC S9(9) COMP.
      *    TIPO_CONTA        CHAR(1) NOT NULL
           05 CNT-TIPO               PIC X(1).
      *    STATUS            CHAR(1) NOT NULL DEFAULT 'A'
           05 CNT-STATUS             PIC X(1).
      *    DATA_ABERTURA     DATE NOT NULL
           05 CNT-DATA-ABERTURA      PIC X(10).
      *    SALDO             DECIMAL(13,2) NOT NULL DEFAULT 0
           05 CNT-SALDO              PIC S9(11)V99 COMP-3.
      *    LIMITE            DECIMAL(11,2) NOT NULL DEFAULT 0
           05 CNT-LIMITE             PIC S9(9)V99 COMP-3.
      *    DATA_ULT_MOVTO    TIMESTAMP
           05 CNT-DATA-ULT-MOVTO     PIC X(26).

      *---------------------------------------------------------------*
      * INDICATOR VARIABLES                                           *
      *---------------------------------------------------------------*
       01  DCLIND-CONTA.
           05 IND-DATA-ULT-MOVTO     PIC S9(4) COMP.
