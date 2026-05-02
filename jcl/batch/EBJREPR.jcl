//* ============================================================
//* ARQUIVO      : EBJREPR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJREPR.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJREPR)
//*
//* FINALIDADE:
//* Reprocessar lancamentos rejeitados que foram corrigidos
//* pela equipe operacional apos o ciclo batch normal.
//*
//* MODO DE EXECUCAO:
//* Sob demanda - fora da cadeia batch diaria automatica.
//* Executar apos correcao manual dos dados no REJEITOS.SEQ.
//*
//* FLUXO DO REPROCESSAMENTO:
//* EBJVALD (gera rejeitos) -> [correcao manual] ->
//* EBJREPR (revalida) -> EBJRPOST (posta recuperados)
//*
//* O QUE ESTE JOB FAZ:
//* 1. Le REJEITOS.SEQ (lancamentos rejeitados pelo EBVALI01)
//* 2. Reaplica as 5 regras de validacao em cada registro
//* 3. Recuperados -> REPR.LANCTO.SEQ (120 bytes)
//* 4. Permanentes -> REPR.REJPERM.SEQ (150 bytes = 120 + motivo)
//* 5. Registra cada decisao na auditoria
//*
//* CODIGOS DE RETORNO:
//* RC 0 = todos os rejeitos recuperados
//* RC 4 = ha rejeitos permanentes ou entrada vazia
//* RC 8 = erro de I/O em algum arquivo
//* ============================================================
//EBJREPR  JOB ,'EMUNAH REPR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: REPROCESSAMENTO (EBREPR01) =======================
//*
//STEP1    EXEC PGM=EBREPR01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBREPR01.
//REJIN    DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=SHR
//* Arquivo de entrada com rejeitos do EBJVALD.
//* DDNAME REJIN esperado pelo programa EBREPR01.
//LCTOUT   DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,DISP=MOD
//* Lancamentos recuperados (passaram na revalidacao).
//* Layout CPLCT001 - 120 bytes. Alimenta o EBJRPOST.
//* DISP=MOD permite reprocessamentos parciais incrementais.
//REJOUT   DD DSN=Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ,DISP=MOD
//* Rejeitos permanentes (falharam na revalidacao).
//* 150 bytes = 120 do registro + 30 de motivo acumulado.
//* DISP=MOD permite acumular as falhas para o housekeeping.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria. DISP=MOD = append no historico do dia.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*