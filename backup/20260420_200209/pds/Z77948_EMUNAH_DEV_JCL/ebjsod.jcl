//* ------------------------------------------------------------
//* ARQUIVO      : EBJSOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSOD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJSOD)
//* FINALIDADE:
//* Start of Day: abrir o ciclo batch do laboratorio marcando
//* CTL.STATUS = OPEN.
//*
//* FLUXO ESPERADO:
//* 1. WRTSTAT - IEBGENER grava "OPEN" em ARQ.CTL.STATUS.
//* 2. VERIFY  - IDCAMS LISTCAT para evidencia.
//*
//* OBS: versao IEBGENER. Sera substituida por EBCTL01 (COBOL)
//* na Onda 6, junto com EBJCUTF, EBJCUTE e EBJEOD/CLOSDAY.
//* ------------------------------------------------------------
//EBJSOD   JOB ,'EMUNAH SOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: ABRIR DIA CONTABIL (STATUS = OPEN) ===
//*
//WRTSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
OPEN
/*
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//SYSIN    DD DUMMY
//*
//* === STEP 2: VERIFICA STATUS GRAVADO ===
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
/*
