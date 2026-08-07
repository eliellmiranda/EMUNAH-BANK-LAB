//EBALLOBM  JOB ,'EMUNAH ALLOC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP ALOCPDS: PDS DE DESENVOLVIMENTO ====================
//*   IEFBR14 nao executa logica; os PDS sao criados pelos DD.
//*   DSORG=PO = Partitioned Organization (PDS).
//*   SPACE CYL para LOADLIB (modulos maiores), TRK para fontes.
//*
//ALOCPDS  EXEC PGM=IEFBR14
//MAPLIB   DD DSN=Z77948.EMUNAH.DEV.MAPLIB,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(3,2,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0),
//            DSNTYPE=LIBRARY
//*           PDS de mapas BMS para programas CICS online.
//*
//DCLGEN   DD DSN=Z77948.EMUNAH.DEV.DCLGEN,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(3,2,5)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0),
//            DSNTYPE=LIBRARY
//*           PDS de DCLGENs (host variables DB2).
