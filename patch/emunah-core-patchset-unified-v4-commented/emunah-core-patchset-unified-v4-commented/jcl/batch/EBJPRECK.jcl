//* ------------------------------------------------------------
//* ARQUIVO      : EBJPRECK.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPRECK.jcl
//*
//* CONTEXTO DIDATICO:
//* Validar as pré-condições mínimas do ambiente antes da cadeia batch.
//*
//* PAPEL NO LAB:
//* Portão de entrada da cadeia principal.
//*
//* FLUXO RESUMIDO:
//* 1. Confere catálogo das bibliotecas essenciais e dos
//* arquivos masters.
//* 2. Garante que CTL.STATUS existe.
//* 3. Executa o programa EBPCHK01 para validar o conteúdo
//* lógico de CTL.STATUS.
//*
//* OBSERVACOES:
//* - Aceita CTL.STATUS vazio ou CLOSED.
//* - Rejeita OPEN, EOTI e EOFI para evitar iniciar um novo
//* ciclo sobre um dia ainda aberto.
//* ------------------------------------------------------------
//EBJPRECK JOB ,'EMUNAH PRECK',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: LOADLIB ===
//*
//CHKLOAD  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.DEV.LOADLIB') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//*
//* === STEP 2: COPYLIB ===
//*
//CHKCOPY  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.DEV.COPY') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//*
//* === STEP 3: CLIENTE KSDS ===
//*
//CHKCLI   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CLIENTE.KSDS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//*
//* === STEP 4: CONTA KSDS ===
//*
//CHKCNT   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CONTA.KSDS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//*
//* === STEP 5: CTL.STATUS EXISTE ===
//*
//CHKCTL   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//*
//* === STEP 6: CTL.STATUS TEM CONTEUDO ACEITAVEL ===
//*    ACEITA VAZIO OU CLOSED
//*
//CHKSTAT  EXEC PGM=EBPCHK01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
