//EBFNDCI2 JOB (ACCT),'FIND CICS LIB',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* Busca ampla pelo programa DFHECP1$ (tradutor CICS) no        *
//* link pack e em todos os catalogos disponiveis.               *
//*--------------------------------------------------------------*
//FIND     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LVL('SYS1') ALL
/*
