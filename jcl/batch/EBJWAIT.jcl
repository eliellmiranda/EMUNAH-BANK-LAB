//* ------------------------------------------------------------
//* ARQUIVO      : EBJWAIT.jcl
//* CAMINHO LOCAL: jcl/batch/EBJWAIT.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJWAIT)
//* FINALIDADE:
//* File-watcher do STAGE.ENTRADA.SEQ.
//* Garante que o arquivo de entrada foi depositado e nao esta
//* vazio antes de liberar a cadeia diaria (EBJLOAD em diante).
//*
//* FLUXO ESPERADO:
//* 1. CHKEXST - IDCAMS LISTCAT valida catalogo do STAGE.
//* 2. CHKCNT  - ICETOOL COUNT com NOEMPTY aborta se vazio.
//*
//* LIMITACOES DESTA VERSAO:
//* - Nao valida trailer do arquivo.
//* - Nao confere count declarado vs count fisico.
//* - Nao valida hash/MD5 de integridade.
//* Essas checagens entrarao com EBWAIT01 (COBOL) na Onda 5/6.
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