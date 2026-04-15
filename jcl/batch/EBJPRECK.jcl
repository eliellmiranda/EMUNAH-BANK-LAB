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
//* 3. Arquivo de entrada do dia existente
//* 4. VSAM de clientes existente
//* 5. VSAM de contas existente
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
//* === STEP 3: VERIFICAR ARQUIVO DE ENTRADA DO DIA ===
//*
//CHKENTR  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.ENTRADA.SEQ') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = Arquivo de entrada existe.
//* RC 12 = Arquivo de entrada ausente.
//*
//* === STEP 4: VERIFICAR VSAM CLIENTES ===
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
//* === STEP 5: VERIFICAR VSAM CONTAS ===
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
