//* ============================================================
//* ARQUIVO      : EBJLOAD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJLOAD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJLOAD)
//*
//* FINALIDADE:
//* Carregar o arquivo de lancamentos do dia da area de staging
//* para o dataset de producao consumido pela cadeia batch.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJWAIT (valida STAGE) --> EBJLOAD --> EBJVALD (validacao)
//*
//* CODIGOS DE RETORNO:
//* RC 0  = arquivo do dia carregado e catalogado com sucesso
//* RC 8  = dia nao esta OPEN (EBCTL01) - cadeia bloqueada
//* RC 12 = falha na copia ou no catalogo - cadeia bloqueada
//* ============================================================
//EBJLOAD  JOB ,'EMUNAH LOAD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR QUE O DIA ESTA ABERTO ===========
//* Valida se status e OPEN. Impede carga se o dia estiver 
//* fechado ou em horario de corte (EOTI/EOFI).
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,OPEN'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//* Arquivo de controle consultado em modo leitura.
//*
//* === STEP DELPREV: DELETAR ARQUIVO DO DIA ANTERIOR ===========
//* COND=(0,NE): executa apenas se o dia estiver OPEN.
//*
//DELPREV  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//* === STEP COPY: COPIAR STAGE -> ARQ DO DIA ===================
//* IEBGENER promove o arquivo para o ambiente operacional.
//*
//COPY     EXEC PGM=IEBGENER,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.STAGE.ENTRADA.SEQ,DISP=SHR
//* Arquivo recebido de sistemas externos (Staging).
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Dataset oficial do ciclo batch (LRECL=120).
//SYSIN    DD DUMMY
//*
//* === STEP VERIFY: CONFIRMAR CATALOGO =========================
//* Garante que o arquivo existe antes de liberar o EBJVALD.
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.ENTRADA.SEQ') ALL
  IF LASTCC > 0 THEN -
     SET MAXCC = 12
/*