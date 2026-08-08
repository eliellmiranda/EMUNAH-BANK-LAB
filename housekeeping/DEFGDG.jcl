//DEFGDG   JOB (ACCT),'DEFINE GDG BASE',CLASS=A,MSGCLASS=H,
//             NOTIFY=&SYSUID
//*------------------------------------------------------------------
//* DEFGDG - SETUP UNICO - roda uma vez so, antes do primeiro EBHKLOG
//* Cria a base GDG onde o EBHKLOG vai gravar o relatorio EREP do
//* LOGREC (uma geracao por execucao, LIMIT(14) guarda ~14 rodadas).
//*------------------------------------------------------------------
//STEP1    EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
  DEFINE GDG (NAME(ELIEL.EMUNAH.EBHKLOG.RPT) -
       LIMIT(14)                             -
       NOEMPTY                               -
       SCRATCH)
/*
