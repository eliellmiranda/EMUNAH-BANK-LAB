--#SET TERMINATOR ;
-- ================================================================
-- EMUNAH BANK LAB — DB2 DDL
-- Schema  : EMUNAH
-- System  : VS01 / DBD1 / 192.168.100.150
-- ================================================================
-- SOURCE OF TRUTH: COBOL host variables (EBCLDB01) and VSAM
-- copybooks in ELIEL.EMUNAH.DEV.COPY.
-- The old EMUNAH-DDL.sql is superseded by this file.
--
-- TABLE NAMING CONVENTION: CD prefix (matches live tables on DBD1)
--   CDCLI  — clients   (VSAM: CLIENTE.KSDS  / copybook: CPCLI001)
--   CDCNT  — accounts  (VSAM: CONTA.KSDS    / copybook: CPCNT001)
--   CDLCT  — movements (VSAM: LANCTO.ESDS   / copybook: CPLCT001)
--   CDEXT  — extract   (VSAM: EXTRATO.GDG   / copybook: CPEXT001)
--   CDREJ  — rejects   (VSAM: REJEITOS.SEQ  / copybook: CPREJ001)
--   CDAUD  — audit     (VSAM: AUDIT.SEQ     / copybook: CPAUD001)
--
-- DATA TYPE DERIVATION RULES (from COBOL sources):
--   PIC 9(5) key        → INTEGER NOT NULL
--   PIC 9(4)/9(8) key   → INTEGER NOT NULL   (AGENCIA, NUM_CONTA)
--   PIC X(n)            → CHAR(n) NOT NULL
--   PIC 9(8) AAAAMMDD   → DATE NOT NULL       (converted by EBCLDB01)
--   PIC S9(11)V99       → DECIMAL(13,2) NOT NULL
--   PIC  9(9)V99        → DECIMAL(11,2) NOT NULL
--   PIC 9(6)            → DECIMAL(6,0) NOT NULL
--   PIC X(n) nullable   → VARCHAR(n)
--   identity column     → INTEGER GENERATED ALWAYS AS IDENTITY
-- ================================================================

SET CURRENT SQLID   = 'EMUNAH';
SET CURRENT SCHEMA  = 'EMUNAH';

-- ================================================================
-- TABLE 1: CDCLI — Clients
-- VSAM source : ELIEL.EMUNAH.ARQ.CLIENTE.KSDS
-- Copybook    : CPCLI001  (80 bytes)
-- COBOL loader: EBCLDB01  (already tested against this table)
--
-- COBOL→DB2 field mapping:
--   CLI-ID-CLIENTE  PIC 9(5)  → hv PIC S9(9) COMP  → INTEGER
--   CLI-NOME        PIC X(30) → hv PIC X(30)        → CHAR(30)
--   CLI-CPF         PIC 9(11) → hv PIC X(11)        → CHAR(11)
--   CLI-DATA-NASC   PIC 9(8)  → hv PIC X(10) (conv) → DATE
--   CLI-STATUS      PIC X(1)  → hv PIC X(1)         → CHAR(1)
--   CLI-DATA-CAD    PIC 9(8)  → hv PIC X(10) (conv) → DATE
-- ================================================================
CREATE TABLE EMUNAH.CDCLI (
    CLI_ID_CLIENTE   INTEGER         NOT NULL,
    CLI_NOME         VARCHAR(30)     NOT NULL,
    CLI_CPF          CHAR(11)        NOT NULL,
    CLI_DATA_NASC    DATE            NOT NULL,
    CLI_STATUS       CHAR(1)         NOT NULL WITH DEFAULT 'A',
    CLI_DATA_CAD     DATE            NOT NULL WITH DEFAULT CURRENT DATE,
    CONSTRAINT PK_CDCLI
        PRIMARY KEY (CLI_ID_CLIENTE),
    CONSTRAINT CK_CDCLI_STATUS
        CHECK (CLI_STATUS IN ('A','I','B'))
) ;

-- ================================================================
-- TABLE 2: CDCNT — Accounts
-- VSAM source : ELIEL.EMUNAH.ARQ.CONTA.KSDS
-- Copybook    : CPCNT001  (100 bytes)
-- COBOL loader: (future EBCNTDB01 — no DB2 loader yet)
--
-- COBOL→DB2 field mapping:
--   CNT-AGENCIA       PIC 9(4)      → INTEGER  (matches live CDCNT)
--   CNT-NUM-CONTA     PIC 9(8)      → INTEGER  (matches live CDCNT)
--   CNT-ID-CLIENTE    PIC 9(5)      → INTEGER  (FK → CDCLI)
--   CNT-TIPO          PIC X(1)      → CHAR(1)
--   CNT-STATUS        PIC X(1)      → CHAR(1)
--   CNT-DATA-ABERTURA PIC 9(8) AAAA → DATE
--   CNT-SALDO         PIC S9(11)V99 → DECIMAL(13,2)
--   CNT-LIMITE        PIC  9(9)V99  → DECIMAL(11,2)
-- ================================================================
CREATE TABLE EMUNAH.CDCNT (
    CNT_AGENCIA       INTEGER         NOT NULL,
    CNT_NUM_CONTA     INTEGER         NOT NULL,
    CNT_ID_CLIENTE    INTEGER         NOT NULL,
    CNT_TIPO          CHAR(1)         NOT NULL,
    CNT_STATUS        CHAR(1)         NOT NULL WITH DEFAULT 'A',
    CNT_DATA_ABERTURA DATE            NOT NULL WITH DEFAULT CURRENT DATE,
    CNT_SALDO         DECIMAL(13,2)   NOT NULL WITH DEFAULT 0,
    CNT_LIMITE        DECIMAL(11,2)   NOT NULL WITH DEFAULT 0,
    CONSTRAINT PK_CDCNT
        PRIMARY KEY (CNT_AGENCIA, CNT_NUM_CONTA),
    CONSTRAINT FK_CDCNT_CLI
        FOREIGN KEY (CNT_ID_CLIENTE) REFERENCES EMUNAH.CDCLI (CLI_ID_CLIENTE),
    CONSTRAINT CK_CDCNT_TIPO
        CHECK (CNT_TIPO IN ('C','P','S')),
    CONSTRAINT CK_CDCNT_STATUS
        CHECK (CNT_STATUS IN ('A','I','B'))
) ;

-- ================================================================
-- TABLE 3: CDLCT — Movements / Lancamentos
-- VSAM source : ELIEL.EMUNAH.ARQ.LANCTO.ESDS
-- Copybook    : CPLCT001  (120 bytes)
-- COBOL writer: EBVALI01 (writes validated records to LANCTO.ESDS)
--               EBPOST01 (reads LANCTO.ESDS, posts to CONTA.KSDS)
--
-- COBOL→DB2 field mapping:
--   LCT-AGENCIA    PIC 9(4)      → INTEGER
--   LCT-NUM-CONTA  PIC 9(8)      → INTEGER
--   LCT-DATA       PIC 9(8) AAAA → DATE
--   LCT-TIPO       PIC X(1)      → CHAR(1)
--   LCT-VALOR      PIC 9(11)V99  → DECIMAL(13,2)
--   LCT-HISTORICO  PIC X(30)     → CHAR(30)
--   LCT-CANAL      PIC X(10)     → CHAR(10)
--   LCT-LOTE       PIC 9(6)      → DECIMAL(6,0)
--   LCT-NSEQ       PIC 9(6)      → DECIMAL(6,0)
--   LCT-STATUS     PIC X(1)      → CHAR(1)
-- ================================================================
CREATE TABLE EMUNAH.CDLCT (
    LCT_AGENCIA      INTEGER         NOT NULL,
    LCT_NUM_CONTA    INTEGER         NOT NULL,
    LCT_DATA         DATE            NOT NULL,
    LCT_TIPO         CHAR(1)         NOT NULL,
    LCT_VALOR        DECIMAL(13,2)   NOT NULL,
    LCT_HISTORICO    CHAR(30)        NOT NULL WITH DEFAULT '',
    LCT_CANAL        CHAR(10)        NOT NULL WITH DEFAULT '',
    LCT_LOTE         DECIMAL(6,0)    NOT NULL,
    LCT_NSEQ         DECIMAL(6,0)    NOT NULL,
    LCT_STATUS       CHAR(1)         NOT NULL WITH DEFAULT 'P',
    CONSTRAINT PK_CDLCT
        PRIMARY KEY (LCT_LOTE, LCT_NSEQ),
    CONSTRAINT FK_CDLCT_CNT
        FOREIGN KEY (LCT_AGENCIA, LCT_NUM_CONTA)
        REFERENCES EMUNAH.CDCNT (CNT_AGENCIA, CNT_NUM_CONTA),
    CONSTRAINT CK_CDLCT_TIPO
        CHECK (LCT_TIPO IN ('C','D')),
    CONSTRAINT CK_CDLCT_STATUS
        CHECK (LCT_STATUS IN ('P','V','R','C'))
) ;

-- ================================================================
-- TABLE 4: CDEXT — Extract / Statement
-- VSAM source : ELIEL.EMUNAH.ARQ.EXTRATO.GDG
-- Copybook    : CPEXT001  (132 bytes)
-- COBOL writer: EBEXTR01
--
-- COBOL→DB2 field mapping:
--   EXT-AGENCIA       PIC X(4)      → CHAR(4)  (copybook is X, not 9)
--   EXT-NUM-CONTA     PIC X(8)      → CHAR(8)
--   EXT-DATA-MOVTO    PIC X(8) AAAA → DATE (convert on load)
--   EXT-NSEQ          PIC X(6)      → DECIMAL(6,0)
--   EXT-TIPO          PIC X(1)      → CHAR(1)
--   EXT-DESCRICAO     PIC X(30)     → CHAR(30)
--   EXT-VALOR         PIC S9(11)V99 → DECIMAL(13,2)
--   EXT-SALDO-POSICAO PIC S9(11)V99 → DECIMAL(13,2)
--   EXT-CANAL         PIC X(10)     → CHAR(10)
-- NOTE: CPEXT001 uses CHAR keys (X not 9) — kept as CHAR here to
--       match the copybook without conversion.
-- ================================================================
CREATE TABLE EMUNAH.CDEXT (
    EXT_AGENCIA      CHAR(4)         NOT NULL,
    EXT_NUM_CONTA    CHAR(8)         NOT NULL,
    EXT_DATA_MOVTO   DATE            NOT NULL,
    EXT_NSEQ         DECIMAL(6,0)    NOT NULL,
    EXT_TIPO         CHAR(1)         NOT NULL,
    EXT_DESCRICAO    CHAR(30)        NOT NULL WITH DEFAULT,
    EXT_VALOR        DECIMAL(13,2)   NOT NULL,
    EXT_SALDO_APOS   DECIMAL(13,2)   NOT NULL,
    EXT_CANAL        CHAR(10)        NOT NULL WITH DEFAULT,
    EXT_DT_CARGA     TIMESTAMP,
    CONSTRAINT PK_CDEXT
        PRIMARY KEY (EXT_AGENCIA, EXT_NUM_CONTA, EXT_DATA_MOVTO, EXT_NSEQ),
    CONSTRAINT CK_CDEXT_TIPO
        CHECK (EXT_TIPO IN ('C','D'))
) ;

-- ================================================================
-- TABLE 5: CDREJ — Rejects
-- VSAM source : ELIEL.EMUNAH.ARQ.REJEITOS.SEQ
-- Copybook    : CPREJ001  (156 bytes)
-- COBOL writer: EBVALI01, EBPOST01
--
-- COBOL→DB2 field mapping:
--   REJ-COD-MOTIVO   PIC X(4)   → CHAR(4)
--   REJ-TXT-MOTIVO   PIC X(14)  → CHAR(14)
--   REJ-TIMESTAMP    PIC X(14)  → CHAR(14)  (AAAAMMDDHHMMSS)
--   REJ-ORIGEM       PIC X(4)   → CHAR(4)
--   REJ-REGISTRO-ORIG embeds full CPLCT001 (120 bytes) — stored as
--   individual columns here for queryability.
-- REJ_ID is a surrogate key (IDENTITY) — no VSAM equivalent.
-- ================================================================
CREATE TABLE EMUNAH.CDREJ (
    REJ_ID           INTEGER         NOT NULL
                         GENERATED ALWAYS AS IDENTITY,
    REJ_AGENCIA      INTEGER         NOT NULL,
    REJ_NUM_CONTA    INTEGER         NOT NULL,
    REJ_DATA_LANCTO  DATE            NOT NULL,
    REJ_TIPO         CHAR(1)         NOT NULL,
    REJ_VALOR        DECIMAL(13,2)   NOT NULL,
    REJ_LOTE         DECIMAL(6,0)    NOT NULL,
    REJ_NSEQ         DECIMAL(6,0)    NOT NULL,
    REJ_COD_MOTIVO   CHAR(4)         NOT NULL,
    REJ_TXT_MOTIVO   CHAR(14)        NOT NULL,
    REJ_TIMESTAMP    CHAR(14)        NOT NULL,
    REJ_ORIGEM       CHAR(4)         NOT NULL,
    CONSTRAINT PK_CDREJ
        PRIMARY KEY (REJ_ID),
    CONSTRAINT CK_CDREJ_TIPO
        CHECK (REJ_TIPO IN ('C','D')),
    CONSTRAINT CK_CDREJ_ORIGEM
        CHECK (REJ_ORIGEM IN ('VALI','POST','REPR'))
) ;

-- ================================================================
-- TABLE 6: CDAUD — Audit trail
-- VSAM source : ELIEL.EMUNAH.ARQ.AUDIT.SEQ
-- Copybook    : CPAUD001  (120 bytes)
-- COBOL writer: EBPOST01, EBVALI01, EBCLLOAD, EBEXTR01, EBSNAP01
--
-- COBOL→DB2 field mapping:
--   AU-TIPO-EVENTO   PIC X(4)  → CHAR(4)
--   AU-PROGRAMA      PIC X(8)  → CHAR(8)
--   AU-DATA-EVENTO   PIC 9(8)  → DATE
--   AU-HORA-EVENTO   PIC 9(6)  → CHAR(6)  (HHMMSS)
--   AU-COD-EVENTO    PIC X(10) → CHAR(10)
--   AU-CHAVE-REF     PIC X(20) → CHAR(20)
--   AU-MENSAGEM      PIC X(54) → CHAR(54)
--   AU-COMPLEMENTO   PIC X(10) → CHAR(10)
-- AUD_ID is a surrogate key (IDENTITY) — no VSAM equivalent.
-- ================================================================
CREATE TABLE EMUNAH.CDAUD (
    AUD_ID           INTEGER         NOT NULL
                         GENERATED ALWAYS AS IDENTITY,
    AU_TIPO_EVENTO   CHAR(4)         NOT NULL,
    AU_PROGRAMA      CHAR(8)         NOT NULL,
    AU_DATA_EVENTO   DATE            NOT NULL WITH DEFAULT CURRENT DATE,
    AU_HORA_EVENTO   CHAR(6)         NOT NULL,
    AU_COD_EVENTO    CHAR(10)        NOT NULL,
    AU_CHAVE_REF     CHAR(20)        NOT NULL WITH DEFAULT '',
    AU_MENSAGEM      CHAR(54)        NOT NULL,
    AU_COMPLEMENTO   CHAR(10)        NOT NULL WITH DEFAULT '',
    AUD_TIMESTAMP    TIMESTAMP       NOT NULL WITH DEFAULT CURRENT TIMESTAMP,
    CONSTRAINT PK_CDAUD
        PRIMARY KEY (AUD_ID),
    CONSTRAINT CK_CDAUD_TIPO
        CHECK (AU_TIPO_EVENTO IN ('INFO','ERRO','REJT','OK  ','WARN'))
) ;
