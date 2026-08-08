      *===============================================================*
      * COPYBOOK: DCLLCT                                             *
      * FUNCAO  : DCLGEN DA TABELA DB2 EMUNAH.CDLCT                  *
      *                                                               *
      * TABELA  : EMUNAH.CDLCT                                        *
      * SISTEMA : VS01 / DBD1 / 192.168.100.150                       *
      *                                                               *
      * SOURCE OF TRUTH:                                              *
      *   VSAM copybook : ELIEL.EMUNAH.DEV.COPY(CPLCT001)            *
      *                                                               *
      * COBOL->DB2 TYPE MAPPING:                                      *
      *   LCT_AGENCIA    INTEGER      -> PIC S9(9) COMP               *
      *   LCT_NUM_CONTA  INTEGER      -> PIC S9(9) COMP               *
      *   LCT_DATA       DATE         -> PIC X(10) 'AAAA-MM-DD'       *
      *   LCT_TIPO       CHAR(1)      -> PIC X(1)                     *
      *   LCT_VALOR      DECIMAL(13,2)-> PIC S9(11)V99 COMP-3         *
      *   LCT_HISTORICO  CHAR(30)     -> PIC X(30)                    *
      *   LCT_CANAL      CHAR(10)     -> PIC X(10)                    *
      *   LCT_LOTE       DECIMAL(6,0) -> PIC S9(6) COMP-3             *
      *   LCT_NSEQ       DECIMAL(6,0) -> PIC S9(6) COMP-3             *
      *   LCT_STATUS     CHAR(1)      -> PIC X(1)                     *
      *                                                               *
      * NO NULLABLE COLUMNS — no indicator variables needed.          *
      *===============================================================*

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

      *---------------------------------------------------------------*
      * HOST VARIABLES — EMUNAH.CDLCT                                 *
      *---------------------------------------------------------------*
       01  DCLTB-CDLCT.

      *-- LCT_AGENCIA: INTEGER NOT NULL (FK part 1 -> CDCNT)        *
           05 LCT-AGENCIA            PIC S9(9) COMP.

      *-- LCT_NUM_CONTA: INTEGER NOT NULL (FK part 2 -> CDCNT)      *
           05 LCT-NUM-CONTA          PIC S9(9) COMP.

      *-- LCT_DATA: DATE NOT NULL                                   *
      *   VSAM source: LCT-DATA PIC 9(8) AAAAMMDD — convert STRING  *
           05 LCT-DATA               PIC X(10).

      *-- LCT_TIPO: CHAR(1) NOT NULL                                *
      *   C=Credito / D=Debito                                       *
           05 LCT-TIPO               PIC X(1).

      *-- LCT_VALOR: DECIMAL(13,2) NOT NULL                         *
      *   VSAM: LCT-VALOR PIC 9(11)V99 — unsigned; use S9 for DB2   *
           05 LCT-VALOR              PIC S9(11)V99 COMP-3.

      *-- LCT_HISTORICO: CHAR(30) NOT NULL DEFAULT ''               *
           05 LCT-HISTORICO          PIC X(30).

      *-- LCT_CANAL: CHAR(10) NOT NULL DEFAULT ''                   *
           05 LCT-CANAL              PIC X(10).

      *-- LCT_LOTE: DECIMAL(6,0) NOT NULL (PK part 1)              *
           05 LCT-LOTE               PIC S9(6) COMP-3.

      *-- LCT_NSEQ: DECIMAL(6,0) NOT NULL (PK part 2)              *
           05 LCT-NSEQ               PIC S9(6) COMP-3.

      *-- LCT_STATUS: CHAR(1) NOT NULL DEFAULT 'P'                  *
      *   P=Pendente / V=Validado / R=Rejeitado / C=Conciliado       *
           05 LCT-STATUS             PIC X(1).

           EXEC SQL END DECLARE SECTION END-EXEC.
