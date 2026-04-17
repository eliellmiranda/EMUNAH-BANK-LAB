//* ------------------------------------------------------------
//* ARQUIVO      : EBJLOAD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJLOAD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJLOAD)
//* FINALIDADE:
//* Verificar se o arquivo de entrada do dia existe e esta catalogado.
//*
//* FLUXO ESPERADO:
//* 1. Consultar o catalogo do z/OS.
//* 2. Validar a existencia de ARQ.ENTRADA.SEQ.
//* 3. Retornar RC=0 se existir.
//* 4. Retornar RC alto para bloquear a cadeia se faltar.
//* ------------------------------------------------------------
//EBJLOAD  JOB ,'EMUNAH LOAD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//PRECHECK EXEC PGM=IDCAMS
//* Executa utilitario de catalogo e administracao de datasets.
//SYSPRINT DD SYSOUT=*
//* Relatorio do IDCAMS.
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.ENTRADA.SEQ') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = arquivo existe.
//* RC 12 = arquivo ausente ou inacessivel.
