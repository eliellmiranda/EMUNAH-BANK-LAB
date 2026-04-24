*===============================================================*
      * COPYBOOK: DCLCONTA                                            *
      * FUNCAO  : DCLGEN DA TABELA DB2 TB_CONTA                      *
      *                                                               *
      * TABELA   : EMUNAH.TB_CONTA                                   *
      * OWNER    : EMUNAH                                             *
      * SCHEMA   : Z77948.EMUNAH.DB2                                  *
      *                                                               *
      * ESTE COPYBOOK SIMULA A SAIDA DO UTILITARIO DCLGEN DO DB2.    *
      *                                                               *
      * RELACAO COM O VSAM:                                           *
      * O laboratorio usa VSAM (CPCNT001) como armazenamento primario.*
      * Este DCLGEN seria utilizado em uma versao futura que acesse   *
      * a tabela DB2 em paralelo ou como repositorio alternativo.     *
      * Os nomes de campos CNT-* foram alinhados ao CPCNT001 para    *
      * facilitar MOVE entre host variables e registro VSAM.          *
      *                                                               *
      * INDICATOR VARIABLES:                                          *
      *   Valor -1 : coluna NULL | Valor 0 : valor presente           *
      *===============================================================*

      *---------------------------------------------------------------*
      * HOST VARIABLES - TABELA TB_CONTA                              *
      *---------------------------------------------------------------*
       01  DCLTB-CONTA.

      *-- AGENCIA: SMALLINT NOT NULL                                *
      *   Parte da chave primaria composta (agencia + num_conta)     *
      *   DB2: SMALLINT (2 bytes) -> COBOL: PIC S9(4) COMP           *
           05 CNT-AGENCIA            PIC S9(4) COMP.

      *-- NUM_CONTA: INTEGER NOT NULL                               *
      *   Parte da chave primaria composta                           *
      *   DB2: INTEGER (4 bytes) -> COBOL: PIC S9(9) COMP            *
           05 CNT-NUM-CONTA          PIC S9(9) COMP.

      *-- ID_CLIENTE: INTEGER NOT NULL (FK -> TB_CLIENTE)           *
      *   Chave estrangeira para o cadastro de clientes              *
           05 CNT-ID-CLIENTE         PIC S9(9) COMP.

      *-- TIPO_CONTA: CHAR(1) NOT NULL                              *
      *   C=Corrente / P=Poupanca / S=Salario                        *
           05 CNT-TIPO               PIC X(1).

      *-- STATUS: CHAR(1) NOT NULL DEFAULT 'A'                      *
      *   A=Ativa / I=Inativa / B=Bloqueada                         *
           05 CNT-STATUS             PIC X(1).

      *-- DATA_ABERTURA: DATE NOT NULL                              *
      *   Formato retornado pelo DB2: 'AAAA-MM-DD' (10 bytes)        *
           05 CNT-DATA-ABERTURA      PIC X(10).

      *-- SALDO: DECIMAL(13,2) NOT NULL DEFAULT 0                   *
      *   13 digitos totais, 2 decimais                              *
      *   DB2: DECIMAL -> COBOL: PIC S9(11)V99 COMP-3 (packed)       *
      *   COMP-3 = packed decimal, compativel com DECIMAL DB2         *
           05 CNT-SALDO              PIC S9(11)V99 COMP-3.

      *-- LIMITE: DECIMAL(11,2) NOT NULL DEFAULT 0                  *
      *   Limite de credito da conta                                 *
      *   DB2: DECIMAL(11,2) -> COBOL: PIC S9(9)V99 COMP-3           *
           05 CNT-LIMITE             PIC S9(9)V99 COMP-3.

      *-- DATA_ULT_MOVTO: TIMESTAMP (nullable)                      *
      *   Ultima movimentacao; NULL se nunca houve lancamento         *
      *   DB2: TIMESTAMP -> COBOL: PIC X(26) (26 bytes)              *
      *   Formato: 'AAAA-MM-DD-HH.MM.SS.ffffff'                      *
      *   Verificar IND-DATA-ULT-MOVTO antes de usar                 *
           05 CNT-DATA-ULT-MOVTO     PIC X(26).

      *---------------------------------------------------------------*
      * INDICATOR VARIABLES                                           *
      *---------------------------------------------------------------*
       01  DCLIND-CONTA.
           05 IND-DATA-ULT-MOVTO     PIC S9(4) COMP.  *> -1=NULL