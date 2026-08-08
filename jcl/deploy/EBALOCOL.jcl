//EBALOCOL JOB (ACCT),'ALLOC ONLINE LIB',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* EBALOCOL - ALOCA ELIEL.EMUNAH.ONLINE.LOADLIB                *
//*                                                              *
//* EXECUTAR UMA UNICA VEZ antes de submeter EBCSSLDJ.           *
//* Biblioteca de load modules dos programas CICS online.        *
//* Mesmo DCB da DEV.LOADLIB: RECFM=U, programas executaveis.   *
//*--------------------------------------------------------------*
//ALLOC    EXEC PGM=IEFBR14
//ONLLIB   DD DSN=ELIEL.EMUNAH.ONLINE.LOADLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,
//             SPACE=(TRK,(30,10,20)),
//             DCB=(RECFM=U,LRECL=0,BLKSIZE=4096,DSORG=PO)
