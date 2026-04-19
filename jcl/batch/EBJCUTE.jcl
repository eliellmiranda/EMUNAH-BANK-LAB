//* ------------------------------------------------------------
//* ARQUIVO      : EBJCUTE.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTE.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCUTE)
//* FINALIDADE:
//* Cutoff Contabil (EOFI - End Of Financial Input):
//* fecha a janela contabil do dia marcando
//* CTL.STATUS = EOFI.
//*
//* FLUXO ESPERADO:
//* 1. WRTSTAT - IEBGENER grava "EOFI" em ARQ.CTL.STATUS.
//* 2. VERIFY  - IDCAMS LISTCAT para evidencia.
//*
//* OBS: versao IEBGENER. Sera substituida por EBCTL01 (COBOL)
//* na Onda 6, junto com EBJSOD, EBJCUTF e EBJEOD/CLOSDAY.
//* ------------------------------------------------------------
//EBJCUTE  JOB ,'EMUNAH CUTE',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: FECHAR JANELA CONTABIL (STATUS = EOFI) ===
//*
//WRTSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
EOFI
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