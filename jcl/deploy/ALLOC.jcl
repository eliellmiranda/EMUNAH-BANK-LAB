//* ------------------------------------------------------------
//* ARQUIVO      : EBALLOC.jcl
//* CAMINHO LOCAL: jcl/deploy/EBALLOC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBALLOC)
//* FINALIDADE:
//* Alocar todos os datasets necessarios para o laboratorio.
//* Executar uma unica vez na preparacao inicial do ambiente.
//*
//* DATASETS CRIADOS:
//* - PDS de desenvolvimento (COBOL, COPY, JCL, LOADLIB)
//* - VSAM KSDS (Clientes, Contas)
//* - VSAM ESDS (Lancamentos)
//* - Sequenciais de apoio: ENTRADA, STAGE, REJEITOS, AUDIT,
//*   SALDO, CONCIL, REPR.LANCTO, CTL.STATUS
//* - Sequenciais de seed
//* ------------------------------------------------------------
//EBALLOC  JOB ,'EMUNAH ALLOC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//ALOCSEQ  EXEC PGM=IEFBR14
//CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//REPRLCT  DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
