//EBFNDCI5 JOB (ACCT),'FIND CICS DSN',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* CICS TS 6.1 esta ativo mas SDFHLOAD nao esta catalogado.     *
//* Este job usa DISPLAY PROG para localizar DFHECP1$ no LLA     *
//* e dump do LINKLIST via operador.                             *
//*--------------------------------------------------------------*
//STEP1    EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=SYS1.LINKLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD *
  EXEC 'SYS1.SAMPLIB(DFHSMUTL)'
/*
//*
//STEP2    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENTRIES('SYS1.LPALIB') ALL
  LISTCAT LVL('SYS2') ALL
  LISTCAT LVL('SYS3') ALL
  LISTCAT LVL('SYS4') ALL
  LISTCAT LVL('INSTALL') ALL
  LISTCAT LVL('MVSVOL') ALL
  LISTCAT LVL('Z31') ALL
  LISTCAT LVL('ZOS') ALL
  LISTCAT LVL('ZOS31') ALL
  LISTCAT LVL('MVSX') ALL
  LISTCAT LVL('MVSXA') ALL
  LISTCAT LVL('SMP') ALL
  LISTCAT LVL('SMPE') ALL
  LISTCAT LVL('SMPNTS') ALL
  LISTCAT LVL('SYS1.DFH') ALL
  LISTCAT LVL('SYS1.SDFH') ALL
/*
