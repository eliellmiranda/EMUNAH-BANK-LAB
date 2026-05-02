//* ============================================================
//* ARQUIVO      : EBJPRECK.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPRECK.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJPRECK)
//*
//* FINALIDADE:
//* Validar pre-condicoes do ambiente antes da cadeia batch.
//* Se qualquer recurso estiver ausente, ou se o status do dia
//* anterior nao estiver CLOSED, o job termina com RC > 0,
//* bloqueando o inicio do novo ciclo.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJPRECK (06:00) --> EBJSOD (06:05) --> EBJWAIT --> ...
//*
//* VERIFICACOES (6 steps):
//* 1. CHKLOAD : LOADLIB catalogada e acessivel
//* 2. CHKCOPY : Biblioteca de copybooks catalogada
//* 3. CHKCLI  : VSAM de clientes existente
//* 4. CHKCNT  : VSAM de contas existente
//* 5. CHKLANC : VSAM ESDS de lancamentos existente
//* 6. CHKCTL  : CTL.STATUS com valor 'CLOSED' (EBCTL01 modo CHK)
//*
//* LOGICA DE ABORT EM CASCATA:
//* COND=(0,NE) em todos os steps apos o primeiro garante
//* que se qualquer step falhar (RC != 0), os subsequentes
//* nao executam - o job encerra com o RC do step que falhou.
//*
//* CODIGOS DE RETORNO:
//* RC 0  = Todos os recursos ok e dia anterior fechado
//* RC 8  = Falha na validacao logica do status (EBCTL01)
//* RC 12 = Algum recurso fisico ausente (IDCAMS)
//* ============================================================
//EBJPRECK JOB ,'EMUNAH PRECK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKLOAD: VERIFICAR LOADLIB =========================
//*
//CHKLOAD  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.DEV.LOADLIB') ALL
  IF LASTCC > 0 THEN -
     SET MAXCC = 12
/*
//* RC 0 = LOADLIB catalogada | RC 12 = LOADLIB ausente
//*
//* === STEP CHKCOPY: VERIFICAR BIBLIOTECA DE COPYBOOKS =========
//*
//CHKCOPY  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.DEV.COPY') ALL
  IF LASTCC > 0 THEN -
     SET MAXCC = 12
/*
//* RC 0 = COPY lib catalogada | RC 12 = COPY lib ausente
//*
//* === STEP CHKCLI: VERIFICAR VSAM CLIENTES ====================
//*
//CHKCLI   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CLIENTE.KSDS') ALL
  IF LASTCC > 0 THEN -
     SET MAXCC = 12
/*
//* RC 0 = KSDS de clientes ok | RC 12 = ausente
//*
//* === STEP CHKCNT: VERIFICAR VSAM CONTAS ======================
//*
//CHKCNT   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CONTA.KSDS') ALL
  IF LASTCC > 0 THEN -
     SET MAXCC = 12
/*
//* RC 0 = KSDS de contas ok | RC 12 = ausente
//*
//* === STEP CHKLANC: VERIFICAR VSAM LANCAMENTOS ================
//*
//CHKLANC  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.LANCTO.ESDS') ALL
  IF LASTCC > 0 THEN -
     SET MAXCC = 12
/*
//* RC 0 = ESDS de lancamentos ok | RC 12 = ausente
//*
//* === STEP CHKCTL: VERIFICAR STATUS DO DIA ANTERIOR ===========
//* Usa o EBCTL01 em modo de checagem passiva (CHK).
//* Garante que a cadeia so avance se o status for CLOSED.
//* O COND=(0,NE) garante que so executa se os VSAMs existirem.
//*
//CHKCTL   EXEC PGM=EBCTL01,PARM='CHK,CLOSED',COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*