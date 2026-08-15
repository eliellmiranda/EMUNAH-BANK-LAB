//EBFNDCI3 JOB (ACCT),'FIND DFHECP1',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* Localiza DFHECP1$ via AMBLIST - mostra em qual biblioteca    *
//* o programa do tradutor CICS esta carregado no sistema.       *
//*--------------------------------------------------------------*
//AMBLIST  EXEC PGM=AMBLIST
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTIDR MODULE='DFHECP1$'
/*
