//* ------------------------------------------------------------
//* ARQUIVO      : EBJSOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSOD.jcl
//*
//* CONTEXTO DIDATICO:
//* Abrir o dia operacional do laboratório gravando CTL.STATUS=OPEN.
//*
//* PAPEL NO LAB:
//* Start of Day do ciclo batch.
//*
//* FLUXO RESUMIDO:
//* 1. Invoca EBCTL01 com PARM=OPEN.
//* 2. Registra a transição válida de CLOSED/vazio para OPEN.
//* 3. Gera evidência no spool da transição realizada.
//*
//* OBSERVACOES:
//* - Deve rodar após EBJPRECK ter liberado a cadeia.
//* ------------------------------------------------------------
//EBJSOD   JOB ,'EMUNAH SOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//SOD      EXEC PGM=EBCTL01,PARM='OPEN'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//VERIFY   EXEC PGM=IEBGENER,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSIN    DD DUMMY
