//* ------------------------------------------------------------
//* ARQUIVO      : EBJPRECK.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPRECK.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJPRECK)
//* FINALIDADE:
//* Validar pre-condicoes do ambiente antes da cadeia batch.
//* Se algum recurso estiver ausente, o job termina com RC=12
//* bloqueando a execucao dos jobs dependentes.
//*
//* VERIFICACOES:
//* 1. LOADLIB catalogada e acessivel
//* 2. Copybook library catalogada
//* 3. VSAM de clientes existente
//* 4. VSAM de contas existente
//* 5. Dataset de controle CTL.STATUS existente (EBJSOD rodou)
//*
//* NOTA: a verificacao do arquivo de entrada do dia migrou
//*       para o job EBJWAIT.jcl, que alem do LISTCAT faz
//*       checagem de trailer, contagem e hash.
//* ------------------------------------------------------------
//EBJPRECK JOB ,'EMUNAH PRECK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: VERIFICAR LOADLIB ===
//*
//CHKLOAD  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.DEV.LOADLIB') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = LOADLIB catalogada.
//* RC 12 = LOADLIB ausente.
//*
//* === STEP 2: VERIFICAR COPYBOOKS ===
//*
//CHKCOPY  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.DEV.COPY') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = COPY library catalogada.
//* RC 12 = COPY library ausente.
//*
//* === STEP 3: VERIFICAR VSAM CLIENTES ===
//*
//CHKCLI   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CLIENTE.KSDS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = VSAM de clientes catalogado.
//* RC 12 = VSAM de clientes ausente.
//*
//* === STEP 4: VERIFICAR VSAM CONTAS ===
//*
//CHKCNT   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CONTA.KSDS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = VSAM de contas catalogado.
//* RC 12 = VSAM de contas ausente.
//*
//* === STEP 5: VERIFICAR DATASET DE CONTROLE (CTL.STATUS) ===
//*
//CHKCTL   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = Dataset de status do branch catalogado (EBJSOD ja executou).
//* RC 12 = Dataset de status ausente - cadeia nao pode prosseguir.
