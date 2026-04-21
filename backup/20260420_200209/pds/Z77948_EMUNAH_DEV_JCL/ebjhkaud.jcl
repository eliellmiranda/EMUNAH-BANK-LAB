//* ------------------------------------------------------------
//* ARQUIVO      : EBJHKAUD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKAUD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKAUD)
//* FINALIDADE:
//* Housekeeping ativo do ARQ.AUDIT.SEQ: arquiva o conteudo
//* corrente em BKP.AUDIT.GDG(+1) e recria o arquivo vazio,
//* evitando crescimento indefinido via DISP=MOD.
//*
//* FLUXO ESPERADO:
//* 1. ARCHAUD  - IEBGENER copia AUDIT.SEQ -> BKP.AUDIT.GDG(+1).
//* 2. DELAUD   - IDCAMS deleta AUDIT.SEQ atual.
//* 3. ALLOCAUD - IEFBR14 recria AUDIT.SEQ vazio.
//*
//* Roda tipicamente no fim do ciclo diario, apos EBJEOD.
//* ------------------------------------------------------------
//EBJHKAUD JOB ,'EMUNAH HKAUD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: ARQUIVAR AUDIT.SEQ EM BKP.AUDIT.GDG(+1) ===
//*
//ARCHAUD  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=SHR
//SYSUT2   DD DSN=Z77948.EMUNAH.BKP.AUDIT.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSIN    DD DUMMY
//*
//* === STEP 2: DELETAR AUDIT.SEQ ATUAL ===
//*
//DELAUD   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.AUDIT.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//* === STEP 3: REALOCAR AUDIT.SEQ VAZIO ===
//*
//ALLOCAUD EXEC PGM=IEFBR14,COND=(0,NE)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
