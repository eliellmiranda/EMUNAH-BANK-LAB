//* ------------------------------------------------------------
//* ARQUIVO      : EBJSNAP.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSNAP.jcl
//*
//* CONTEXTO DIDATICO:
//* Fotografar o saldo consolidado do dia em ARQ.SALDO.GDG(+1).
//*
//* PAPEL NO LAB:
//* Snapshot oficial do saldo diário.
//*
//* FLUXO RESUMIDO:
//* 1. Executa EBSNAP01.
//* 2. Lê CONTA.KSDS.
//* 3. Grava uma nova geração de SALDO.GDG.
//*
//* OBSERVACOES:
//* - Esta versão substitui o uso indevido de EBSALD01.
//* - EBSALD01 continua existindo apenas como consulta manual.
//* ------------------------------------------------------------
//EBJSNAP  JOB ,'EMUNAH SNAP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//STEP1    EXEC PGM=EBSNAP01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//SALDOUT  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
