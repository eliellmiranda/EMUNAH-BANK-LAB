//* ------------------------------------------------------------
//* ARQUIVO      : EBJLOAD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJLOAD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJLOAD)
//* FINALIDADE:
//* Carregar o arquivo de lancamentos do dia da area de staging
//* para o DSN de producao consumido pela cadeia batch.
//*
//* Simula o job que em producao move o arquivo recebido via
//* FTP/Connect:Direct do sistema externo para o ARQ do dia.
//*
//* PRE-CONDICOES:
//* - EBJWAIT ja validou STAGE.ENTRADA.SEQ (trailer, count, hash).
//* - CTL.BRANCH.STATUS = OPEN (validado pelo EBJPRECK).
//*
//* FLUXO:
//* 1. DELPREV  - Apaga ARQ.ENTRADA.SEQ do dia anterior (se existir).
//* 2. COPY     - IEBGENER copia STAGE.ENTRADA.SEQ -> ARQ.ENTRADA.SEQ.
//* 3. VERIFY   - LISTCAT confirma que ARQ.ENTRADA.SEQ ficou catalogado.
//*
//* RC 0  = carga concluida com sucesso.
//* RC 12 = falha na copia ou no catalogo - cadeia bloqueada.
//* ------------------------------------------------------------
//EBJLOAD  JOB ,'EMUNAH LOAD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: DELETAR ARQ DO DIA ANTERIOR ===
//*
//DELPREV  EXEC PGM=IDCAMS
//* Remove o ARQ.ENTRADA.SEQ do dia anterior antes da nova carga.
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.SEQ' NONVSAM
  SET MAXCC = 0
/*
//* MAXCC=0 forcado para nao falhar no primeiro run (quando
//* o dataset ainda nao existe). O IDCAMS reporta RC=8 quando
//* tenta deletar um DSN que nao esta catalogado; isso e normal.
//*
//* === STEP 2: COPIAR STAGE -> ARQ ===
//*
//COPY     EXEC PGM=IEBGENER
//* Copia sequencial FB-120 do staging para o arquivo do dia.
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.STAGE.ENTRADA.SEQ,DISP=SHR
//* Entrada: arquivo recebido do sistema externo, ja validado.
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Saida: arquivo do dia que a cadeia batch ira consumir.
//SYSIN    DD DUMMY
//*
//* === STEP 3: VERIFICAR CATALOGO ===
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//* Confirma que o ARQ.ENTRADA.SEQ ficou catalogado apos a copia.
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.ENTRADA.SEQ') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*
//* RC 0  = arquivo do dia carregado e catalogado.
//* RC 12 = catalogo nao encontra o arquivo (copia falhou).
