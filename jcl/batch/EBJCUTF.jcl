//* ------------------------------------------------------------
//* ARQUIVO      : EBJCUTF.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTF.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCUTF)
//* FINALIDADE:
//* Cutoff Financeiro (EOTI - End Of Transaction Input):
//* fecha a janela de entrada de movimentos do dia marcando
//* CTL.STATUS = EOTI.
//*
//* FLUXO ESPERADO:
//* 1. WRTSTAT - IEBGENER grava "EOTI" em ARQ.CTL.STATUS.
//* 2. VERIFY  - IDCAMS LISTCAT para evidencia.
//*
//* OBS: versao IEBGENER. Sera substituida por EBCTL01 (COBOL)
//* na Onda 6, junto com EBJSOD, EBJCUTE e EBJEOD/CLOSDAY.
//* ------------------------------------------------------------
//EBJCUTF  JOB ,'EMUNAH CUTF',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: FECHAR JANELA DE INPUT (STATUS = EOTI) ===
//*
//WRTSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
EOTI
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