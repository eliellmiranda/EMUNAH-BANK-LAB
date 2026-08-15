//EBFNDCI4 JOB (ACCT),'FIND CICS DSN',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* Tenta localizar a biblioteca CICS por multiplos HLQs         *
//* conhecidos em instalacoes Hercules / z/OS 3.1                *
//*--------------------------------------------------------------*
//FIND     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LVL('CICSTS61') ALL
  LISTCAT LVL('CICSTS60') ALL
  LISTCAT LVL('CICSTS55') ALL
  LISTCAT LVL('CICSTS') ALL
  LISTCAT LVL('CICS610') ALL
  LISTCAT LVL('CICS600') ALL
  LISTCAT LVL('CICS') ALL
  LISTCAT LVL('DFH') ALL
  LISTCAT LVL('DFH610') ALL
  LISTCAT LVL('DFH600') ALL
  LISTCAT LVL('DFHSM') ALL
  LISTCAT LVL('PP.CICS') ALL
  LISTCAT LVL('IBM') ALL
/*
