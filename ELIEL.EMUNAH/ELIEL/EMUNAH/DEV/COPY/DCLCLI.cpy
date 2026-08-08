      *===============================================================*
      * COPYBOOK: DCLCLI                                             *
      * FUNCAO  : DCLGEN DA TABELA DB2 EMUNAH.CDCLI                  *
      *                                                               *
      * TABELA  : EMUNAH.CDCLI                                        *
      * SISTEMA : VS01 / DBD1 / 192.168.100.150                       *
      *                                                               *
      * SOURCE OF TRUTH:                                              *
      *   VSAM copybook : ELIEL.EMUNAH.DEV.COPY(CPCLI001)            *
      *   COBOL host var: EBCLDB01 (tested, SQLCODE=0)                *
      *                                                               *
      * COBOL->DB2 TYPE MAPPING:                                      *
      *   CLI_ID_CLIENTE INTEGER     -> PIC S9(9) COMP                *
      *   CLI_NOME       CHAR(30)    -> PIC X(30)                     *
      *   CLI_CPF        CHAR(11)    -> PIC X(11)                     *
      *   CLI_DATA_NASC  DATE        -> PIC X(10) 'AAAA-MM-DD'        *
      *   CLI_STATUS     CHAR(1)     -> PIC X(1)                      *
      *   CLI_DATA_CAD   DATE        -> PIC X(10) 'AAAA-MM-DD'        *
      *                                                               *
      * DATE CONVERSION (VSAM->DB2):                                  *
      *   VSAM stores dates as PIC 9(8) in format AAAAMMDD.           *
      *   EBCLDB01 converts to 'AAAA-MM-DD' via STRING before INSERT. *
      *   DB2 returns dates as 'AAAA-MM-DD' (10 chars) on SELECT.     *
      *                                                               *
      * NO NULLABLE COLUMNS — no indicator variables needed.          *
      *===============================================================*

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

      *---------------------------------------------------------------*
      * HOST VARIABLES — EMUNAH.CDCLI                                 *
      *---------------------------------------------------------------*
       01  DCLTB-CDCLI.

      *-- CLI_ID_CLIENTE: INTEGER NOT NULL (PK)                     *
      *   DB2 INTEGER (4 bytes) -> COBOL PIC S9(9) COMP (fullword)  *
           05 CLI-ID-CLIENTE         PIC S9(9) COMP.

      *-- CLI_NOME: VARCHAR(30) NOT NULL                            *
      *   DB2 VARCHAR in COBOL: use PIC X(30) host var.             *
      *   DB2 will right-pad on INSERT; trailing spaces are trimmed  *
      *   on SELECT. Functionally identical to CHAR(30) for COBOL.  *
           05 CLI-NOME               PIC X(30).

      *-- CLI_CPF: CHAR(11) NOT NULL                                *
           05 CLI-CPF                PIC X(11).

      *-- CLI_DATA_NASC: DATE NOT NULL                              *
      *   DB2 DATE returned as 'AAAA-MM-DD' (10 chars)              *
      *   VSAM source: PIC 9(8) AAAAMMDD — convert before INSERT    *
           05 CLI-DATA-NASC          PIC X(10).

      *-- CLI_STATUS: CHAR(1) NOT NULL DEFAULT 'A'                  *
      *   A=Ativo / I=Inativo / B=Bloqueado                         *
           05 CLI-STATUS             PIC X(1).

      *-- CLI_DATA_CAD: DATE NOT NULL DEFAULT CURRENT DATE          *
      *   DB2 DATE returned as 'AAAA-MM-DD' (10 chars)              *
           05 CLI-DATA-CAD           PIC X(10).

           EXEC SQL END DECLARE SECTION END-EXEC.
