//EBALOCOL JOB (ACCT),'REALLOC ONLINE LIB',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* EBALOCOL - RECRIA ELIEL.EMUNAH.ONLINE.LOADLIB COMO PDSE     *
//*                                                              *
//* MOTIVO: IEW2606S — Program Object (gerado pelo compilador    *
//*   COBOL moderno) nao pode ser salvo em PDS convencional.     *
//*   PDSE (DSNTYPE=LIBRARY) aceita Program Objects.             *
//*                                                              *
//* EXECUTAR UMA UNICA VEZ, depois resubmeter EBCSSLDJ.          *
//*--------------------------------------------------------------*
//DELETE   EXEC PGM=IEFBR14
//ONLLIB   DD DSN=ELIEL.EMUNAH.ONLINE.LOADLIB,
//             DISP=(MOD,DELETE,DELETE),
//             UNIT=SYSDA,
//             SPACE=(TRK,(1,1))
//*
//ALLOC    EXEC PGM=IEFBR14
//ONLLIB   DD DSN=ELIEL.EMUNAH.ONLINE.LOADLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,
//             SPACE=(TRK,(30,10,20)),
//             DCB=(RECFM=U,LRECL=0,BLKSIZE=4096,DSORG=PO),
//             DSNTYPE=LIBRARY
