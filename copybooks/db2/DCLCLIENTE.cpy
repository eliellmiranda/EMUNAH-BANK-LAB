      *===============================================================*
      * COPYBOOK: DCLCLIENTE                                          *
      * FUNCAO  : DCLGEN DA TABELA DB2 TB_CLIENTE                     *
      *                                                               *
      * TABELA   : EMUNAH.TB_CLIENTE                                  *
      * OWNER    : EMUNAH                                             *
      *                                                               *
      * ESTE COPYBOOK SIMULA A SAIDA DO UTILITARIO DCLGEN DO DB2     *
      * PARA USO EM PROGRAMAS QUE ACESSAM A TABELA DE CLIENTES       *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA HOST VARIABLES - TABELA TB_CLIENTE                       *
      *---------------------------------------------------------------*
       01  DCLTB-CLIENTE.
      *    ID_CLIENTE        INTEGER NOT NULL
           05 CLI-ID-CLIENTE         PIC S9(9) COMP.
      *    NOME              VARCHAR(30) NOT NULL
           05 CLI-NOME.
              49 CLI-NOME-LEN        PIC S9(4) COMP.
              49 CLI-NOME-TEXT       PIC X(30).
      *    CPF               CHAR(11) NOT NULL
           05 CLI-CPF                PIC X(11).
      *    DATA_NASCIMENTO   DATE
           05 CLI-DATA-NASC          PIC X(10).
      *    STATUS            CHAR(1) NOT NULL DEFAULT 'A'
           05 CLI-STATUS             PIC X(1).
      *    DATA_CADASTRO     TIMESTAMP NOT NULL
           05 CLI-DATA-CAD           PIC X(26).
      *    AGENCIA_PRINC     SMALLINT
           05 CLI-AGENCIA-PRINC      PIC S9(4) COMP.

      *---------------------------------------------------------------*
      * INDICATOR VARIABLES                                           *
      *---------------------------------------------------------------*
       01  DCLIND-CLIENTE.
           05 IND-DATA-NASC          PIC S9(4) COMP.
           05 IND-AGENCIA-PRINC      PIC S9(4) COMP.
