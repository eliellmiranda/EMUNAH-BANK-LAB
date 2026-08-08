//EBFNDCIC JOB (ACCT),'FIND CICS LIB',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* Localiza o HLQ correto da biblioteca CICS SDFHLOAD           *
//* Verifique no SYSPRINT qual entrada aparece                   *
//*--------------------------------------------------------------*
//FIND     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LVL('DFH') ALL
  LISTCAT LVL('CICSTS') ALL
  LISTCAT LVL('CICS') ALL
  LISTCAT LVL('SYS1.CICS') ALL
/*
