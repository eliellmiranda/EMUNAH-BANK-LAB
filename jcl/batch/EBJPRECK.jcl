//* ============================================================
//* ARQUIVO      : EBJPRECK.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPRECK.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJPRECK)
//*
//* FINALIDADE:
//*   Validar pre-condicoes do ambiente antes da cadeia batch.
//*   Se qualquer recurso estiver ausente ou inacessivel,
//*   o job termina com RC=12 bloqueando os jobs dependentes.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJSOD --> EBJPRECK --> EBJWAIT --> EBJLOAD --> ...
//*
//* VERIFICACOES (5 steps):
//*   1. CHKLOAD : LOADLIB catalogada e acessivel
//*   2. CHKCOPY : Biblioteca de copybooks catalogada
//*   3. CHKCLI  : VSAM de clientes existente
//*   4. CHKCNT  : VSAM de contas existente
//*   5. CHKCTL  : CTL.STATUS existente (EBJSOD ja rodou)
//*
//* LOGICA DE ABORT EM CASCATA:
//*   COND=(0,NE) em todos os steps apos o primeiro garante
//*   que se qualquer step falhar (RC != 0), os subsequentes
//*   nao executam - o job encerra com o RC do step que falhou.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = todos os recursos confirmados - cadeia pode prosseguir
//*   RC 12 = algum recurso ausente - CADEIA BLOQUEADA
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
//*           RC 0 = LOADLIB catalogada | RC 12 = LOADLIB ausente
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
//*           RC 0 = COPY lib catalogada | RC 12 = COPY lib ausente
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
//*           RC 0 = KSDS de clientes ok | RC 12 = ausente
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
//*           RC 0 = KSDS de contas ok | RC 12 = ausente
//*
//* === STEP CHKCTL: VERIFICAR CTL.STATUS (EBJSOD rodou) ========
//*   Se CTL.STATUS nao existe, EBJSOD nao executou.
//*   A cadeia nao pode prosseguir sem o Start of Day.
//*
//CHKCTL   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//*           RC 0 = CTL.STATUS ok (EBJSOD ja executou)
//*           RC 12 = CTL.STATUS ausente - EBJSOD nao rodou