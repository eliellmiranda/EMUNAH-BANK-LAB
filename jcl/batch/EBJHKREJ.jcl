//* ------------------------------------------------------------
//* ARQUIVO      : EBJHKREJ.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKREJ.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKREJ)
//* FINALIDADE:
//* Housekeeping ativo do ARQ.REJEITOS.SEQ: arquiva o
//* conteudo corrente em BKP.REJEITOS.GDG(+1) e recria o
//* arquivo vazio, evitando crescimento indefinido causado
//* pelas gravacoes diarias do EBJVALD.
//*
//* FLUXO ESPERADO:
//* 1. ARCHREJ  - IEBGENER copia REJEITOS.SEQ -> BKP.REJEITOS.GDG(+1).
//* 2. DELREJ   - IDCAMS deleta REJEITOS.SEQ atual.
//* 3. ALLOCREJ - IEFBR14 recria REJEITOS.SEQ vazio.
//*
//* Roda tipicamente no fim do ciclo diario, apos EBJRPOST
//* ter fechado o ciclo de reprocessamento.
//* ------------------------------------------------------------
//EBJHKREJ JOB ,'EMUNAH HKREJ',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: ARQUIVAR REJEITOS.SEQ EM BKP.REJEITOS.GDG(+1) ===
//*
//ARCHREJ  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=SHR
//SYSUT2   DD DSN=Z77948.EMUNAH.BKP.REJEITOS.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSIN    DD DUMMY
//*
//* === STEP 2: DELETAR REJEITOS.SEQ ATUAL ===
//*
//DELREJ   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.REJEITOS.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//* === STEP 3: REALOCAR REJEITOS.SEQ VAZIO ===
//*
//ALLOCREJ EXEC PGM=IEFBR14,COND=(0,NE)
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)