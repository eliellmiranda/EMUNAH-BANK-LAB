//EBALLOC  JOB ,'EMUNAH ALOC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*-----------------------------------------------------------------*
//* RECRIA DATASETS SEQUENCIAIS JA APAGADOS                         *
//*-----------------------------------------------------------------*
//ALLOC    EXEC PGM=IEFBR14
//CLIENTES DD  DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(1,1),RLSE),
//             DCB=(DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=800)
//CONTAS   DD  DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(1,1),RLSE),
//             DCB=(DSORG=PS,RECFM=FB,LRECL=100,BLKSIZE=1000)
//AUDIT    DD  DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(5,1),RLSE),
//             DCB=(DSORG=PS,RECFM=FB,LRECL=120,BLKSIZE=1200)
