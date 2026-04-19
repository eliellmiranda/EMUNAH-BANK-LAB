//* ------------------------------------------------------------
//* ARQUIVO      : EBJBACKP.jcl
//* CAMINHO LOCAL: jcl/batch/EBJBACKP.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJBACKP)
//* FINALIDADE:
//* Registrar o estado anterior do ambiente (backup logico)
//* antes da execucao da cadeia batch principal.
//* Saidas migradas para GDG: cada execucao gera uma nova
//* geracao, retencao controlada pela base GDG.
//*
//* O QUE ESTE JOB FAZ:
//* 1. Exporta o VSAM de clientes para BKP.CLIENTE.GDG(+1).
//* 2. Exporta o VSAM de contas    para BKP.CONTA.GDG(+1).
//* 3. Copia a auditoria corrente  para BKP.AUDIT.GDG(+1).
//*
//* Em caso de falha, permite restauracao do estado pre-batch
//* a partir das geracoes (-N) das bases GDG.
//* ------------------------------------------------------------
//EBJBACKP JOB ,'EMUNAH BKUP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: BACKUP VSAM CLIENTES ===
//*
//BKPCLI   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//OUTFILE  DD DSN=Z77948.EMUNAH.BKP.CLIENTE.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=80,BLKSIZE=0)
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
//OUTFILE  DD DSN=Z77948.EMUNAH.BKP.CONTA.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=100,BLKSIZE=0)
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
//SYSUT2   DD DSN=Z77948.EMUNAH.BKP.AUDIT.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSIN    DD DUMMY
//* Copia o arquivo de auditoria como snapshot pre-batch.