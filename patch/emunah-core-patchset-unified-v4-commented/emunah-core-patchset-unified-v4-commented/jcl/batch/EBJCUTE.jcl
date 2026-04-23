//* ------------------------------------------------------------
//* ARQUIVO      : EBJCUTE.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTE.jcl
//*
//* CONTEXTO DIDATICO:
//* Fechar a janela contábil do dia gravando CTL.STATUS=EOFI.
//*
//* PAPEL NO LAB:
//* Cutoff contábil.
//*
//* FLUXO RESUMIDO:
//* 1. Invoca EBCTL01 com PARM=EOFI.
//* 2. Marca o ponto a partir do qual o dia está pronto para
//* conciliação e extrato.
//* 3. Gera evidência da transição no spool.
//*
//* OBSERVACOES:
//* - Substitui a versão antiga baseada em IEBGENER.
//* ------------------------------------------------------------
//EBJCUTE  JOB ,'EMUNAH CUTE',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//CUTE     EXEC PGM=EBCTL01,PARM='EOFI'
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
