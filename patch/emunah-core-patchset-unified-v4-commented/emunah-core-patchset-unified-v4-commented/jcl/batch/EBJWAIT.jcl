//* ------------------------------------------------------------
//* ARQUIVO      : EBJWAIT.jcl
//* CAMINHO LOCAL: jcl/batch/EBJWAIT.jcl
//*
//* CONTEXTO DIDATICO:
//* Checar se o arquivo do dia chegou ao staging e não está vazio.
//*
//* PAPEL NO LAB:
//* File-watcher manual do laboratório.
//*
//* FLUXO RESUMIDO:
//* 1. Verifica se STAGE.ENTRADA.SEQ está catalogado.
//* 2. Conta registros / valida não-vazio.
//* 3. Bloqueia a cadeia se o arquivo não estiver pronto.
//*
//* OBSERVACOES:
//* - Evita promover para ARQ um arquivo ausente ou vazio.
//* ------------------------------------------------------------
//EBJWAIT  JOB ,'EMUNAH WAIT',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: VERIFICA EXISTENCIA DO STAGE ===
//*
//CHKEXST  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.STAGE.ENTRADA.SEQ') ALL
/*
//*
//* === STEP 2: CONTA REGISTROS (ABORTA SE VAZIO) ===
//*
//CHKCNT   EXEC PGM=ICETOOL,COND=(0,NE)
//TOOLMSG  DD SYSOUT=*
//DFSMSG   DD SYSOUT=*
//STAGE    DD DSN=Z77948.EMUNAH.STAGE.ENTRADA.SEQ,DISP=SHR
//TOOLIN   DD *
  COUNT FROM(STAGE) NOEMPTY
/*
