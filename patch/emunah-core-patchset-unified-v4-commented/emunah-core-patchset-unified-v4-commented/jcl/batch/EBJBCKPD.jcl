//* ------------------------------------------------------------
//* ARQUIVO      : EBJBCKPD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJBCKPD.jcl
//*
//* CONTEXTO DIDATICO:
//* Gerar backup lógico pré-batch de clientes, contas e auditoria.
//*
//* PAPEL NO LAB:
//* Proteção de rollback antes do processamento do dia.
//*
//* FLUXO RESUMIDO:
//* 1. Exporta CLIENTE.KSDS para BKP.CLIENTE.GDG(+1).
//* 2. Exporta CONTA.KSDS para BKP.CONTA.GDG(+1).
//* 3. Copia AUDIT.SEQ para BKP.AUDIT.GDG(+1).
//*
//* OBSERVACOES:
//* - Usado para preservar baseline operacional antes da
//* aplicação dos lançamentos.
//* ------------------------------------------------------------
//EBJBACKP JOB ,'EMUNAH BKUP',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: BACKUP VSAM CLIENTES ===
//*
//BKPCLI   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//INFILE   DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//OUTFILE  DD DSN=Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG(+1),
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
//OUTFILE  DD DSN=Z77948.EMUNAH.ARQ.BKP.CONTA.GDG(+1),
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
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSIN    DD DUMMY
//* Copia o arquivo de auditoria como snapshot pre-batch.
