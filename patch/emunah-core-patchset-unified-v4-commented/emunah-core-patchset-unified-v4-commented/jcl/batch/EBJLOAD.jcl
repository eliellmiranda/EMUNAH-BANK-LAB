//* ------------------------------------------------------------
//* ARQUIVO      : EBJLOAD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJLOAD.jcl
//*
//* CONTEXTO DIDATICO:
//* Promover o arquivo do dia da área STAGE para ARQ.ENTRADA.SEQ.
//*
//* PAPEL NO LAB:
//* Entrada oficial do arquivo na cadeia batch.
//*
//* FLUXO RESUMIDO:
//* 1. Remove a cópia anterior do ARQ.ENTRADA.SEQ, se existir.
//* 2. Copia STAGE.ENTRADA.SEQ para ARQ.ENTRADA.SEQ.
//* 3. Confirma catalogação da nova entrada do dia.
//*
//* OBSERVACOES:
//* - Assume formato FB 120 conforme layout de lançamento do
//* lab.
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
