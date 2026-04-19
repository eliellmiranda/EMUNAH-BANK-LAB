//* ------------------------------------------------------------
//* ARQUIVO      : EBJBCKPD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJBCKPD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJBCKPD)
//* FINALIDADE:
//* Registrar o estado anterior do ambiente (backup logico)
//* antes da execucao da cadeia batch principal.
//*
//* O QUE ESTE JOB FAZ:
//* 1. Exporta o VSAM de clientes para backup sequencial.
//* 2. Exporta o VSAM de contas para backup sequencial.
//* 3. Copia a auditoria corrente como snapshot.
//*
//* Em caso de falha, permite restauracao do estado pre-batch.
//* ------------------------------------------------------------
//EBJBACKP JOB ,'EMUNAH BKUP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: BACKUP VSAM CLIENTES ===
//*
//BKPCLI   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//OUTFILE  DD DSN=Z77948.EMUNAH.BKP.CLIENTE.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//SYSIN    DD *
  REPRO INFILE(INFILE) OUTFILE(OUTFILE)
  IF LASTCC > 0 THEN -
    SET MAXCC = 8
/*
//* Exporta todos os registros do VSAM de clientes.
//*
//* === STEP 2: BACKUP VSAM CONTAS ===
//*
//BKPCNT   EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//OUTFILE  DD DSN=Z77948.EMUNAH.BKP.CONTA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//SYSIN    DD *
  REPRO INFILE(INFILE) OUTFILE(OUTFILE)
  IF LASTCC > 0 THEN -
    SET MAXCC = 8
/*
//* Exporta todos os registros do VSAM de contas.
//*
//* === STEP 3: SNAPSHOT DA AUDITORIA ===
//*
//BKPAUD   EXEC PGM=IEBGENER,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=SHR
//SYSUT2   DD DSN=Z77948.EMUNAH.BKP.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSIN    DD DUMMY
//* Copia o arquivo de auditoria como snapshot pre-batch.
