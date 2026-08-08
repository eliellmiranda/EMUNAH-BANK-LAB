      *===============================================================*
      * COPYBOOK: DCLCNT                                             *
      * FUNCAO  : DCLGEN DA TABELA DB2 EMUNAH.CDCNT                  *
      *                                                               *
      * TABELA  : EMUNAH.CDCNT                                        *
      * SISTEMA : VS01 / DBD1 / 192.168.100.150                       *
      *                                                               *
      * SOURCE OF TRUTH:                                              *
      *   VSAM copybook : ELIEL.EMUNAH.DEV.COPY(CPCNT001)            *
      *   Live table    : confirmed INTEGER keys via DBeaver           *
      *                                                               *
      * COBOL->DB2 TYPE MAPPING:                                      *
      *   CNT_AGENCIA       INTEGER      -> PIC S9(9) COMP            *
      *   CNT_NUM_CONTA     INTEGER      -> PIC S9(9) COMP            *
      *   CNT_ID_CLIENTE    INTEGER      -> PIC S9(9) COMP  (FK)      *
      *   CNT_TIPO          CHAR(1)      -> PIC X(1)                  *
      *   CNT_STATUS        CHAR(1)      -> PIC X(1)                  *
      *   CNT_DATA_ABERTURA DATE         -> PIC X(10) 'AAAA-MM-DD'    *
      *   CNT_SALDO         DECIMAL(13,2)-> PIC S9(11)V99 COMP-3      *
      *   CNT_LIMITE        DECIMAL(11,2)-> PIC S9(9)V99  COMP-3      *
      *                                                               *
      * NOTE ON VSAM KEY CONVERSION:                                  *
      *   CPCNT001 defines CNT-AGENCIA PIC 9(4) and                   *
      *   CNT-NUM-CONTA PIC 9(8). These are DISPLAY numerics.         *
      *   Use a straight MOVE to PIC S9(9) COMP host variable.        *
      *   COBOL handles DISPLAY->COMP binary conversion automatically. *
      *   NUMVAL is for PIC X fields only — do NOT use here.          *
      *                                                               *
      * NO NULLABLE COLUMNS — no indicator variables needed.          *
      *===============================================================*

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

      *---------------------------------------------------------------*
      * HOST VARIABLES — EMUNAH.CDCNT                                 *
      *---------------------------------------------------------------*
       01  DCLTB-CDCNT.

      *-- CNT_AGENCIA: INTEGER NOT NULL (PK part 1)                 *
      *   DB2 INTEGER (4 bytes) -> COBOL PIC S9(9) COMP             *
      *   VSAM source: CNT-AGENCIA PIC 9(4) — convert via NUMVAL    *
           05 CNT-AGENCIA            PIC S9(9) COMP.

      *-- CNT_NUM_CONTA: INTEGER NOT NULL (PK part 2)               *
      *   DB2 INTEGER (4 bytes) -> COBOL PIC S9(9) COMP             *
      *   VSAM source: CNT-NUM-CONTA PIC 9(8) — convert via NUMVAL  *
           05 CNT-NUM-CONTA          PIC S9(9) COMP.

      *-- CNT_ID_CLIENTE: INTEGER NOT NULL (FK -> CDCLI)            *
           05 CNT-ID-CLIENTE         PIC S9(9) COMP.

      *-- CNT_TIPO: CHAR(1) NOT NULL                                *
      *   C=Corrente / P=Poupanca / S=Salario                        *
           05 CNT-TIPO               PIC X(1).

      *-- CNT_STATUS: CHAR(1) NOT NULL DEFAULT 'A'                  *
      *   A=Ativa / I=Inativa / B=Bloqueada                         *
           05 CNT-STATUS             PIC X(1).

      *-- CNT_DATA_ABERTURA: DATE NOT NULL DEFAULT CURRENT DATE     *
      *   DB2 DATE returned as 'AAAA-MM-DD' (10 chars)              *
      *   VSAM source: CNT-DATA-ABERTURA PIC 9(8) — convert STRING  *
           05 CNT-DATA-ABERTURA      PIC X(10).

      *-- CNT_SALDO: DECIMAL(13,2) NOT NULL DEFAULT 0               *
      *   DB2 DECIMAL(13,2) -> COBOL PIC S9(11)V99 COMP-3 (packed)  *
      *   VSAM source: CNT-SALDO PIC S9(11)V99 — compatible         *
           05 CNT-SALDO              PIC S9(11)V99 COMP-3.

      *-- CNT_LIMITE: DECIMAL(11,2) NOT NULL DEFAULT 0              *
      *   DB2 DECIMAL(11,2) -> COBOL PIC S9(9)V99 COMP-3            *
      *   VSAM source: CNT-LIMITE PIC 9(9)V99 — sign-safe COMP-3    *
           05 CNT-LIMITE             PIC S9(9)V99 COMP-3.

           EXEC SQL END DECLARE SECTION END-EXEC.
