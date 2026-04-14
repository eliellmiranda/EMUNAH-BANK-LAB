-- =============================================================
-- EMUNAH BANK LAB - Comandos Db2 uteis para o dia a dia
-- Execute no DB2 Command Line Processor ou DBeaver
-- =============================================================

-- Conectar ao banco local
-- db2 connect to EMUNAH

-- =============================================================
-- VERIFICACOES DE CARGA
-- =============================================================
SELECT 'CLIENTES'    AS TABELA, COUNT(*) AS QT FROM EMUNAH.CLIENTES    UNION ALL
SELECT 'CONTAS'      AS TABELA, COUNT(*) AS QT FROM EMUNAH.CONTAS       UNION ALL
SELECT 'LANCAMENTOS' AS TABELA, COUNT(*) AS QT FROM EMUNAH.LANCAMENTOS  UNION ALL
SELECT 'EXTRATO'     AS TABELA, COUNT(*) AS QT FROM EMUNAH.EXTRATO      UNION ALL
SELECT 'REJEITOS'    AS TABELA, COUNT(*) AS QT FROM EMUNAH.REJEITOS     UNION ALL
SELECT 'AUDITORIA'   AS TABELA, COUNT(*) AS QT FROM EMUNAH.AUDITORIA;


-- =============================================================
-- CONSULTAS BASICAS
-- =============================================================

-- Ver todos os clientes
SELECT * FROM EMUNAH.CLIENTES ORDER BY CLI_ID_CLIENTE;

-- Ver contas com saldo por cliente
SELECT C.CLI_NOME, T.CNT_AGENCIA, T.CNT_NUM_CONTA,
       T.CNT_TIPO, T.CNT_STATUS, T.CNT_SALDO
FROM   EMUNAH.CONTAS T
JOIN   EMUNAH.CLIENTES C ON C.CLI_ID_CLIENTE = T.CNT_ID_CLIENTE
ORDER  BY T.CNT_AGENCIA, T.CNT_NUM_CONTA;

-- Ver lancamentos pendentes
SELECT * FROM EMUNAH.LANCAMENTOS
WHERE  LCT_STATUS = 'P'
ORDER  BY LCT_DATA, LCT_LOTE, LCT_NSEQ;

-- Ver lancamentos rejeitados com motivo
SELECT R.REJ_AGENCIA, R.REJ_NUM_CONTA, R.REJ_COD_MOTIVO,
       R.REJ_DESC_MOTIVO, R.REJ_PROGRAMA, R.REJ_DATA_REJEITO
FROM   EMUNAH.REJEITOS R
ORDER  BY R.REJ_DATA_REJEITO DESC, R.REJ_ID DESC;

-- Ver extrato de uma conta especifica
SELECT EXT_DATA_MOVTO, EXT_NSEQ, EXT_TIPO,
       EXT_DESCRICAO, EXT_VALOR, EXT_SALDO_APOS, EXT_CANAL
FROM   EMUNAH.EXTRATO
WHERE  EXT_AGENCIA   = '0001'
AND    EXT_NUM_CONTA = '00000001'
ORDER  BY EXT_DATA_MOVTO, EXT_NSEQ;

-- Ver log de auditoria por programa
SELECT AU_TIPO_EVENTO, AU_PROGRAMA, AU_DATA_EVENTO,
       AU_HORA_EVENTO, AU_COD_EVENTO, AU_MENSAGEM
FROM   EMUNAH.AUDITORIA
ORDER  BY AUD_ID DESC
FETCH FIRST 50 ROWS ONLY;

-- Ver erros na auditoria
SELECT * FROM EMUNAH.AUDITORIA
WHERE  AU_TIPO_EVENTO IN ('ERRO', 'REJT')
ORDER  BY AUD_TIMESTAMP DESC;


-- =============================================================
-- SIMULACAO DE POSTAGEM (equivalente ao que o EBPOST01 faz)
-- =============================================================

-- Debitar da conta 0001/00000001
UPDATE EMUNAH.CONTAS
SET    CNT_SALDO = CNT_SALDO - 15.00
WHERE  CNT_AGENCIA   = '0001'
AND    CNT_NUM_CONTA = '00000001';

-- Creditar na conta 0001/00000002
UPDATE EMUNAH.CONTAS
SET    CNT_SALDO = CNT_SALDO + 15.00
WHERE  CNT_AGENCIA   = '0001'
AND    CNT_NUM_CONTA = '00000002';

-- Marcar lancamento como validado
UPDATE EMUNAH.LANCAMENTOS
SET    LCT_STATUS = 'V'
WHERE  LCT_LOTE = 1 AND LCT_NSEQ = 1;


-- =============================================================
-- RESET DO LAB (apaga tudo para comecar do zero)
-- =============================================================
-- DELETE FROM EMUNAH.AUDITORIA;
-- DELETE FROM EMUNAH.REJEITOS;
-- DELETE FROM EMUNAH.EXTRATO;
-- DELETE FROM EMUNAH.LANCAMENTOS;
-- DELETE FROM EMUNAH.CONTAS;
-- DELETE FROM EMUNAH.CLIENTES;


-- =============================================================
-- LISTAR TABELAS DO SCHEMA (catalogo do Db2)
-- =============================================================
SELECT TABNAME, CARD AS ESTIMATIVA_LINHAS
FROM   SYSCAT.TABLES
WHERE  TABSCHEMA = 'EMUNAH'
ORDER  BY TABNAME;
