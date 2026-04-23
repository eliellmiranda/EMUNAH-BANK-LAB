//* ------------------------------------------------------------
//* ARQUIVO      : EBJCUTF.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTF.jcl
//*
//* CONTEXTO DIDATICO:
//* Fechar a janela de entrada transacional do dia gravando CTL.STATUS=EOTI.
//*
//* PAPEL NO LAB:
//* Cutoff financeiro / fim do input de transações.
//*
//* FLUXO RESUMIDO:
//* 1. Invoca EBCTL01 com PARM=EOTI.
//* 2. Bloqueia novas postagens na cadeia principal.
//* 3. Abre a janela de accrual e snapshot.
//*
//* OBSERVACOES:
//* - Substitui a versão antiga que gravava texto via
//* IEBGENER.
//* ------------------------------------------------------------
//EBJCUTF  JOB ,'EMUNAH CUTF',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//CUTF     EXEC PGM=EBCTL01,PARM='EOTI'
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
