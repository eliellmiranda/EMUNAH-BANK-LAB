//ALLCBMSJ JOB (ACCT),'ALLOC DEV.BMS',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*------------------------------------------------------------*
//* ALOCACAO DO PDS ELIEL.EMUNAH.DEV.BMS                      *
//* Armazena fontes BMS (mapas de tela CICS)                   *
//* LRECL=80  RECFM=FB  DSORG=PO  BLKSIZE=8000                *
//*------------------------------------------------------------*
//ALLCBMS  EXEC PGM=IEFBR14
//BMS      DD DSN=ELIEL.EMUNAH.DEV.BMS,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,
//             SPACE=(TRK,(5,5,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000,DSORG=PO)
