//* ------------------------------------------------------------
//* ARQUIVO      : EBLISTDS.jcl
//* CAMINHO LOCAL: jcl/util/EBLISTDS.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBLISTDS)
//* FINALIDADE:
//* Listar todos os datasets do laboratorio e verificar
//* se estao catalogados corretamente.
//*
//* UTIL PARA DIAGNOSTICO E INVENTARIO DO AMBIENTE.
//* ------------------------------------------------------------
//EBLISTDS JOB ,'EMUNAH LISTDS',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: LISTAR DATASETS DE DESENVOLVIMENTO ===
//*
//LISTDEV  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.DEV') ALL
/*
//*
//* === STEP 2: LISTAR DATASETS DE DADOS ===
//*
//LISTARQ  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.ARQ') ALL
/*
//*
//* === STEP 3: LISTAR DATASETS DE SEED ===
//*
//LISTSEED EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.SEED') ALL
/*
//*
//* === STEP 4: LISTAR DATASETS DE BACKUP ===
//*
//LISTBKP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.BKP') ALL
/*
