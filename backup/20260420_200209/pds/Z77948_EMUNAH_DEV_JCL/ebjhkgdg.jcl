//* ------------------------------------------------------------
//* ARQUIVO      : EBJHKGDG.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKGDG.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKGDG)
//* FINALIDADE:
//* Housekeeping das bases GDG do laboratorio.
//* Gera evidencia do estado atual de cada base: quantidade
//* de geracoes, LIMIT configurado, atributos de retencao
//* (NOEMPTY/SCRATCH) e lista das geracoes ativas.
//*
//* A expiracao automatica das geracoes antigas e feita pela
//* propria base GDG (NOEMPTY + SCRATCH definidos no EBDEFGDG).
//* Este job NAO faz DELETE ativo: e monitor + evidencia.
//*
//* FLUXO ESPERADO:
//* 1. IDCAMS LISTCAT ALL das 6 bases GDG.
//*    Saida em SYSPRINT, arquivavel como trilha de auditoria.
//* ------------------------------------------------------------
//EBJHKGDG JOB ,'EMUNAH HKGDG',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: LISTCAT DAS BASES GDG ===
//*
//LISTGDG  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.EXTRATO.GDG')      ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.SALDO.GDG')        ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG')  ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.CONTA.GDG')    ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG')    ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.REJEITOS.GDG') ALL
/*
