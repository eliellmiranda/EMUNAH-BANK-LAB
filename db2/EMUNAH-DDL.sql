--=============================================================--
-- EMUNAH BANK LAB - DB2 DDL                                  --
-- Gerado com base nos copybooks e datasets do laboratorio     --
--                                                             --
-- Schema  : EMUNAH                                            --
-- Tabelas : CLIENTES, CONTAS, LANCAMENTOS,                    --
--           EXTRATO, REJEITOS, AUDITORIA                      --
--                                                             --
-- Compativel com: DB2 for z/OS 13 e DB2 LUW (local/Docker)   --
-- Referencia     : Copybooks CPCLI001, CPCNT001, CPLCT001,    --
--                  CPEXT001, CPREJ001, CPAUD001               --
--=============================================================--


-- ============================================================
-- PASSO 0: CRIAR O SCHEMA (se necessario)
-- No z/OS o schema normalmente e o proprio TSOID (ex: Z77948)
-- Em ambiente local/Docker, crie explicitamente:
-- ============================================================
-- CREATE SCHEMA EMUNAH;
-- SET SCHEMA EMUNAH;


-- ============================================================
-- TABELA 1: CLIENTES
-- Fonte: copybook CPCLI001
-- Dataset: Z77948.EMUNAH.ARQ.CLIENTES.KSDS (seed: clientes.txt)
-- ============================================================
CREATE TABLE EMUNAH.CLIENTES (
    CLI_ID_CLIENTE   DECIMAL(5, 0)   NOT NULL,   -- PIC 9(5)   - Chave do cliente
    CLI_NOME         CHAR(30)        NOT NULL,   -- PIC X(30)  - Nome completo
    CLI_CPF          CHAR(11)        NOT NULL,   -- PIC 9(11)  - CPF sem mascara
    CLI_DATA_NASC    CHAR(8)         NOT NULL,   -- PIC 9(8)   - Formato AAAAMMDD
    CLI_STATUS       CHAR(1)         NOT NULL    -- PIC X(1)   - A=Ativo I=Inativo B=Bloqueado
                     WITH DEFAULT 'A',
    CLI_DATA_CAD     CHAR(8)         NOT NULL,   -- PIC 9(8)   - Formato AAAAMMDD

    CONSTRAINT PK_CLIENTES PRIMARY KEY (CLI_ID_CLIENTE),
    CONSTRAINT CK_CLI_STATUS CHECK (CLI_STATUS IN ('A', 'I', 'B')),
    CONSTRAINT CK_CLI_CPF_LEN CHECK (LENGTH(TRIM(CLI_CPF)) = 11)
);

COMMENT ON TABLE EMUNAH.CLIENTES
    IS 'Cadastro de clientes do Emunah Bank Lab. Mapeado do copybook CPCLI001.';


-- ============================================================
-- TABELA 2: CONTAS
-- Fonte: copybook CPCNT001
-- Dataset: Z77948.EMUNAH.ARQ.CONTAS.KSDS (seed: contas.txt)
-- ============================================================
CREATE TABLE EMUNAH.CONTAS (
    CNT_AGENCIA      CHAR(4)         NOT NULL,   -- PIC 9(4)     - Agencia
    CNT_NUM_CONTA    CHAR(8)         NOT NULL,   -- PIC 9(8)     - Numero da conta
    CNT_ID_CLIENTE   DECIMAL(5, 0)   NOT NULL,   -- PIC 9(5)     - FK -> CLIENTES
    CNT_TIPO         CHAR(1)         NOT NULL,   -- PIC X(1)     - C=Corrente P=Poupanca S=Salario
    CNT_STATUS       CHAR(1)         NOT NULL    -- PIC X(1)     - A=Ativa I=Inativa B=Bloqueada
                     WITH DEFAULT 'A',
    CNT_DATA_ABERTURA CHAR(8)        NOT NULL,   -- PIC 9(8)     - Formato AAAAMMDD
    CNT_SALDO        DECIMAL(13, 2)  NOT NULL    -- PIC 9(11)V99 - Saldo atual
                     WITH DEFAULT 0,
    CNT_LIMITE       DECIMAL(11, 2)  NOT NULL    -- PIC 9(9)V99  - Limite/Cheque especial
                     WITH DEFAULT 0,

    CONSTRAINT PK_CONTAS PRIMARY KEY (CNT_AGENCIA, CNT_NUM_CONTA),
    CONSTRAINT FK_CONTAS_CLIENTES FOREIGN KEY (CNT_ID_CLIENTE)
        REFERENCES EMUNAH.CLIENTES (CLI_ID_CLIENTE),
    CONSTRAINT CK_CNT_TIPO   CHECK (CNT_TIPO   IN ('C', 'P', 'S')),
    CONSTRAINT CK_CNT_STATUS CHECK (CNT_STATUS IN ('A', 'I', 'B'))
);

COMMENT ON TABLE EMUNAH.CONTAS
    IS 'Cadastro de contas do Emunah Bank Lab. Mapeado do copybook CPCNT001.';


-- ============================================================
-- TABELA 3: LANCAMENTOS
-- Fonte: copybook CPLCT001
-- Dataset: Z77948.EMUNAH.ARQ.LANCTO.SEQ (entrada: lancamentos_d0.txt)
-- ============================================================
CREATE TABLE EMUNAH.LANCAMENTOS (
    LCT_LOTE         DECIMAL(6, 0)   NOT NULL,   -- PIC 9(6)     - Identificador do lote
    LCT_NSEQ         DECIMAL(6, 0)   NOT NULL,   -- PIC 9(6)     - Sequencial no lote
    LCT_AGENCIA      CHAR(4)         NOT NULL,   -- PIC 9(4)     - Agencia da conta
    LCT_NUM_CONTA    CHAR(8)         NOT NULL,   -- PIC 9(8)     - Numero da conta
    LCT_DATA         CHAR(8)         NOT NULL,   -- PIC 9(8)     - Formato AAAAMMDD
    LCT_TIPO         CHAR(1)         NOT NULL,   -- PIC X(1)     - C=Credito D=Debito
    LCT_VALOR        DECIMAL(13, 2)  NOT NULL,   -- PIC 9(11)V99 - Valor do lancamento
    LCT_HISTORICO    VARCHAR(30)     NOT NULL    -- PIC X(30)    - Descricao do movimento
                     WITH DEFAULT '',
    LCT_CANAL        CHAR(10)        NOT NULL    -- PIC X(10)    - ATM,APP,PIX,CX,INTERNET...
                     WITH DEFAULT '',
    LCT_STATUS       CHAR(1)         NOT NULL    -- PIC X(1)     - P=Pendente V=Validado R=Rejeitado C=Conciliado
                     WITH DEFAULT 'P',

    CONSTRAINT PK_LANCAMENTOS PRIMARY KEY (LCT_LOTE, LCT_NSEQ),
    CONSTRAINT FK_LANCTO_CONTAS FOREIGN KEY (LCT_AGENCIA, LCT_NUM_CONTA)
        REFERENCES EMUNAH.CONTAS (CNT_AGENCIA, CNT_NUM_CONTA),
    CONSTRAINT CK_LCT_TIPO   CHECK (LCT_TIPO   IN ('C', 'D')),
    CONSTRAINT CK_LCT_STATUS CHECK (LCT_STATUS IN ('P', 'V', 'R', 'C')),
    CONSTRAINT CK_LCT_VALOR  CHECK (LCT_VALOR  >= 0)
);

COMMENT ON TABLE EMUNAH.LANCAMENTOS
    IS 'Lancamentos/movimentos bancarios. Mapeado do copybook CPLCT001.';


-- ============================================================
-- TABELA 4: EXTRATO
-- Fonte: copybook CPEXT001
-- Dataset: Z77948.EMUNAH.ARQ.EXTRATO.GDG (saida do EBEXTR01)
-- ============================================================
CREATE TABLE EMUNAH.EXTRATO (
    EXT_AGENCIA      CHAR(4)         NOT NULL,   -- PIC 9(4)      - Agencia
    EXT_NUM_CONTA    CHAR(8)         NOT NULL,   -- PIC 9(8)      - Numero da conta
    EXT_DATA_MOVTO   CHAR(8)         NOT NULL,   -- PIC 9(8)      - Formato AAAAMMDD
    EXT_NSEQ         DECIMAL(6, 0)   NOT NULL,   -- PIC 9(6)      - Sequencial no dia
    EXT_TIPO         CHAR(1)         NOT NULL,   -- PIC X(1)      - C=Credito D=Debito
    EXT_DESCRICAO    VARCHAR(30)     NOT NULL    -- PIC X(30)     - Descricao do movimento
                     WITH DEFAULT '',
    EXT_VALOR        DECIMAL(13, 2)  NOT NULL,   -- PIC S9(11)V99 - Valor (sinalizado)
    EXT_SALDO_APOS   DECIMAL(13, 2)  NOT NULL,   -- PIC S9(11)V99 - Saldo apos movimento
    EXT_CANAL        CHAR(10)        NOT NULL    -- PIC X(10)     - Canal de origem
                     WITH DEFAULT '',
    EXT_DT_CARGA     TIMESTAMP       NOT NULL    -- Controle: momento da carga no DB2
                     WITH DEFAULT CURRENT TIMESTAMP,

    CONSTRAINT PK_EXTRATO PRIMARY KEY (EXT_AGENCIA, EXT_NUM_CONTA, EXT_DATA_MOVTO, EXT_NSEQ),
    CONSTRAINT FK_EXTRATO_CONTAS FOREIGN KEY (EXT_AGENCIA, EXT_NUM_CONTA)
        REFERENCES EMUNAH.CONTAS (CNT_AGENCIA, CNT_NUM_CONTA),
    CONSTRAINT CK_EXT_TIPO CHECK (EXT_TIPO IN ('C', 'D'))
);

COMMENT ON TABLE EMUNAH.EXTRATO
    IS 'Extrato gerado pelo programa EBEXTR01. Mapeado do copybook CPEXT001.';


-- ============================================================
-- TABELA 5: REJEITOS
-- Fonte: copybook CPREJ001
-- Dataset: Z77948.EMUNAH.ARQ.REJEITO.SEQ (saida do EBVALI01/EBPOST01)
-- ============================================================
CREATE TABLE EMUNAH.REJEITOS (
    REJ_ID           INTEGER         NOT NULL    -- Surrogate key (auto-gerado)
                     GENERATED ALWAYS AS IDENTITY,
    REJ_AGENCIA      CHAR(4)         NOT NULL,   -- PIC 9(4)      - Agencia
    REJ_NUM_CONTA    CHAR(8)         NOT NULL,   -- PIC 9(8)      - Numero da conta
    REJ_DATA_LANCTO  CHAR(8)         NOT NULL,   -- PIC 9(8)      - Data original AAAAMMDD
    REJ_TIPO_LANCTO  CHAR(1)         NOT NULL,   -- PIC X(1)      - C=Credito D=Debito
    REJ_VALOR        DECIMAL(13, 2)  NOT NULL,   -- PIC S9(11)V99 - Valor original
    REJ_NSEQ_ORIG    DECIMAL(6, 0)   NOT NULL,   -- PIC 9(6)      - Seq. original no lote
    REJ_COD_MOTIVO   CHAR(4)         NOT NULL,   -- PIC X(4)      - R001..R006
    REJ_DESC_MOTIVO  VARCHAR(40)     NOT NULL,   -- PIC X(40)     - Descricao do motivo
    REJ_PROGRAMA     CHAR(8)         NOT NULL,   -- PIC X(8)      - Programa que rejeitou
    REJ_DATA_REJEITO CHAR(8)         NOT NULL,   -- PIC 9(8)      - Data da rejeicao AAAAMMDD
    REJ_HORA_REJEITO CHAR(8)         NOT NULL,   -- PIC 9(8)      - Hora HHMMSSTH

    CONSTRAINT PK_REJEITOS PRIMARY KEY (REJ_ID),
    CONSTRAINT CK_REJ_TIPO   CHECK (REJ_TIPO_LANCTO IN ('C', 'D')),
    CONSTRAINT CK_REJ_MOTIVO CHECK (REJ_COD_MOTIVO IN
        ('R001','R002','R003','R004','R005','R006'))
);

COMMENT ON TABLE EMUNAH.REJEITOS
    IS 'Lancamentos rejeitados (EBVALI01/EBPOST01). Mapeado do copybook CPREJ001.';


-- ============================================================
-- TABELA 6: AUDITORIA
-- Fonte: copybook CPAUD001
-- Alimentada por todos os programas batch do lab
-- ============================================================
CREATE TABLE EMUNAH.AUDITORIA (
    AUD_ID           INTEGER         NOT NULL    -- Surrogate key (auto-gerado)
                     GENERATED ALWAYS AS IDENTITY,
    AU_TIPO_EVENTO   CHAR(4)         NOT NULL,   -- PIC X(4)  - INFO,ERRO,REJT,OK,WARN
    AU_PROGRAMA      CHAR(8)         NOT NULL,   -- PIC X(8)  - Ex: EBCLLOAD, EBPOST01
    AU_DATA_EVENTO   CHAR(8)         NOT NULL,   -- PIC 9(8)  - Formato AAAAMMDD
    AU_HORA_EVENTO   CHAR(8)         NOT NULL,   -- PIC 9(8)  - Formato HHMMSSTH
    AU_COD_EVENTO    CHAR(10)        NOT NULL,   -- PIC X(10) - Ex: CLIOK001, CNTERR01
    AU_CHAVE_REF     CHAR(20)        NOT NULL    -- PIC X(20) - ID cliente, chave conta, job
                     WITH DEFAULT '',
    AU_MENSAGEM      VARCHAR(60)     NOT NULL,   -- PIC X(60) - Descricao do evento
    AU_COMPLEMENTO   CHAR(10)        NOT NULL    -- PIC X(10) - Contexto adicional
                     WITH DEFAULT '',
    AUD_TIMESTAMP    TIMESTAMP       NOT NULL    -- Controle: momento exato do registro
                     WITH DEFAULT CURRENT TIMESTAMP,

    CONSTRAINT PK_AUDITORIA PRIMARY KEY (AUD_ID),
    CONSTRAINT CK_AUD_TIPO CHECK (AU_TIPO_EVENTO IN ('INFO','ERRO','REJT','OK  ','WARN'))
);

COMMENT ON TABLE EMUNAH.AUDITORIA
    IS 'Log de auditoria batch do Emunah Bank Lab. Mapeado do copybook CPAUD001.';


-- ============================================================
-- INDICES ADICIONAIS (desempenho e consultas frequentes)
-- ============================================================

-- Consulta de lancamentos por conta e data (EBEXTR01, EBJCONC)
CREATE INDEX EMUNAH.IX_LANCTO_CONTA_DATA
    ON EMUNAH.LANCAMENTOS (LCT_AGENCIA, LCT_NUM_CONTA, LCT_DATA);

-- Consulta de lancamentos por status (EBJVALD, EBJPOST)
CREATE INDEX EMUNAH.IX_LANCTO_STATUS
    ON EMUNAH.LANCAMENTOS (LCT_STATUS);

-- Consulta de rejeitos por conta
CREATE INDEX EMUNAH.IX_REJEITOS_CONTA
    ON EMUNAH.REJEITOS (REJ_AGENCIA, REJ_NUM_CONTA);

-- Consulta de auditoria por programa e data
CREATE INDEX EMUNAH.IX_AUDITORIA_PROG_DATA
    ON EMUNAH.AUDITORIA (AU_PROGRAMA, AU_DATA_EVENTO);

-- Consulta de auditoria por tipo de evento (monitoramento)
CREATE INDEX EMUNAH.IX_AUDITORIA_TIPO
    ON EMUNAH.AUDITORIA (AU_TIPO_EVENTO);


-- ============================================================
-- CARGA INICIAL (seed) - CLIENTES
-- Baseado em: data/seed/clientes.txt
-- ============================================================
INSERT INTO EMUNAH.CLIENTES VALUES (1,  'JOAO SILVA',           '12345678901', '19900101', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (2,  'MARIA SOUZA',          '12345678902', '19850215', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (3,  'PEDRO SANTOS',         '12345678903', '19920310', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (4,  'ANA COSTA',            '12345678904', '19880411', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (5,  'CARLA MORAES',         '12345678905', '19910509', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (6,  'LUCAS BARBOSA',        '12345678906', '19870612', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (7,  'BRUNO LIMA',           '12345678907', '19900718', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (8,  'PAULA ALMEIDA',        '12345678908', '19860823', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (9,  'RENATA ARAUJO',        '12345678909', '19930914', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (10, 'FABIO PEREIRA',        '12345678910', '19891011', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (11, 'MARTA FERNANDES',      '12345678911', '19841103', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (12, 'GUSTAVO ROCHA',        '12345678912', '19901207', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (13, 'JULIANA TEIXEIRA',     '12345678913', '19910112', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (14, 'THIAGO RIBEIRO',       '12345678914', '19870218', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (15, 'FERNANDA MELO',        '12345678915', '19920305', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (16, 'DANIEL OLIVEIRA',      '12345678916', '19880422', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (17, 'AMANDA MARTINS',       '12345678917', '19890517', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (18, 'RODRIGO NUNES',        '12345678918', '19860626', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (19, 'CAMILA GOMES',         '12345678919', '19900710', 'A', '20260312');
INSERT INTO EMUNAH.CLIENTES VALUES (20, 'RAFAEL DUARTE',        '12345678920', '19910819', 'A', '20260312');


-- ============================================================
-- CARGA INICIAL (seed) - CONTAS
-- Baseado em: data/seed/contas.txt
-- Padrao: agencia 0001, contas 00000001..00000040
--         saldo inicial R$ 1.100,00 ate R$ 5.000,00
--         limite fixo   R$   500,00
-- ============================================================
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000001', 1,  'C','A','20260312', 1100.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000002', 1,  'P','A','20260312', 1200.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000003', 2,  'C','A','20260312', 1300.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000004', 2,  'P','A','20260312', 1400.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000005', 3,  'C','A','20260312', 1500.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000006', 3,  'P','A','20260312', 1600.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000007', 4,  'C','A','20260312', 1700.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000008', 4,  'P','A','20260312', 1800.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000009', 5,  'C','A','20260312', 1900.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000010', 5,  'P','A','20260312', 2000.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000011', 6,  'C','A','20260312', 2100.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000012', 6,  'P','A','20260312', 2200.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000013', 7,  'C','A','20260312', 2300.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000014', 7,  'P','A','20260312', 2400.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000015', 8,  'C','A','20260312', 2500.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000016', 8,  'P','A','20260312', 2600.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000017', 9,  'C','A','20260312', 2700.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000018', 9,  'P','A','20260312', 2800.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000019', 10, 'C','A','20260312', 2900.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000020', 10, 'P','A','20260312', 3000.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000021', 11, 'C','A','20260312', 3100.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000022', 11, 'P','A','20260312', 3200.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000023', 12, 'C','A','20260312', 3300.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000024', 12, 'P','A','20260312', 3400.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000025', 13, 'C','A','20260312', 3500.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000026', 13, 'P','A','20260312', 3600.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000027', 14, 'C','A','20260312', 3700.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000028', 14, 'P','A','20260312', 3800.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000029', 15, 'C','A','20260312', 3900.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000030', 15, 'P','A','20260312', 4000.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000031', 16, 'C','A','20260312', 4100.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000032', 16, 'P','A','20260312', 4200.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000033', 17, 'C','A','20260312', 4300.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000034', 17, 'P','A','20260312', 4400.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000035', 18, 'C','A','20260312', 4500.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000036', 18, 'P','A','20260312', 4600.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000037', 19, 'C','A','20260312', 4700.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000038', 19, 'P','A','20260312', 4800.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000039', 20, 'C','A','20260312', 4900.00,  500.00);
INSERT INTO EMUNAH.CONTAS VALUES ('0001','00000040', 20, 'P','A','20260312', 5000.00,  500.00);


-- ============================================================
-- VERIFICACAO RAPIDA (execute apos a carga)
-- ============================================================
-- SELECT COUNT(*) AS QT_CLIENTES    FROM EMUNAH.CLIENTES;
-- SELECT COUNT(*) AS QT_CONTAS      FROM EMUNAH.CONTAS;
-- SELECT COUNT(*) AS QT_LANCAMENTOS FROM EMUNAH.LANCAMENTOS;
-- SELECT COUNT(*) AS QT_EXTRATO     FROM EMUNAH.EXTRATO;
-- SELECT COUNT(*) AS QT_REJEITOS    FROM EMUNAH.REJEITOS;
-- SELECT COUNT(*) AS QT_AUDITORIA   FROM EMUNAH.AUDITORIA;
