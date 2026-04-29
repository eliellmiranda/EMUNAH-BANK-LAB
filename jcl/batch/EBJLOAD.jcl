//* ============================================================
//* ARQUIVO      : EBJLOAD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJLOAD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJLOAD)
//*
//* FINALIDADE:
//* Carregar o arquivo de lancamentos do dia da area de staging
//* para o dataset de producao consumido pela cadeia batch.
//* Simula o job que em producao move o arquivo recebido via
//* FTP/Connect:Direct do sistema externo.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJWAIT (valida STAGE) --> EBJLOAD --> EBJVALD (validacao)
//*
//* PRE-CONDICOES:
//* - EBJWAIT ja confirmou STAGE.ENTRADA.SEQ nao vazio
//* - CTL.STATUS = OPEN (validador pelo step CHKSTAT)
//* - EBJPRECK confirmou LOADLIB e VSAMs acessiveis
//*
//* FLUXO DOS 4 STEPS:
//* 1. CHKSTAT : valida se CTL.STATUS = OPEN via EBCTL01
//* 2. DELPREV : remove dataset do dia anterior (idempotente)
//* 3. COPY    : copia STAGE -> ARQ do dia
//* 4. VERIFY  : confirma que o dataset ficou catalogado
//*
//* CODIGOS DE RETORNO:
//* RC 0  = arquivo do dia carregado e catalogado com sucesso
//* RC 8  = dia nao esta OPEN (EBCTL01) - cadeia bloqueada
//* RC 12 = falha na copia ou no catalogo - cadeia bloqueada
//* ============================================================
//EBJLOAD  JOB ,'EMUNAH LOAD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR QUE O DIA ESTA ABERTO ===========
//* Usa o EBCTL01 em modo leitura (CHK) para validar se o
//* status e OPEN. Impede carga se o dia estiver fechado
//* ou em horario de corte (EOTI/EOFI).
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,OPEN'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP DELPREV: DELETAR ARQUIVO DO DIA ANTERIOR ===========
//* Remove ARQ.ENTRADA.SEQ para permitir nova alocacao.
//* Executa apenas se CHKSTAT retornou RC=0.
//* SET MAXCC=0: nao falha se o dataset ainda nao existe
//* (primeiro run do laboratorio ou apos housekeeping).
//* Idempotente: seguro para rerun sem intervencao manual.
//*
//DELPREV  EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//* === STEP COPY: COPIAR STAGE -> ARQ DO DIA ===================
//* IEBGENER faz copia sequencial FB-120 do staging para o
//* dataset de producao que a cadeia batch ira consumir.
//* DISP=(NEW,CATLG,DELETE): aloca, cataloga e apaga em erro.
//*
//COPY     EXEC PGM=IEBGENER,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.STAGE.ENTRADA.SEQ,DISP=SHR
//* Staging: arquivo recebido do sistema externo,
//* ja validado pelo EBJWAIT (nao vazio).
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Dataset do dia: consumido pelo EBJVALD (EBVALI01).
//SYSIN    DD DUMMY
//*
//* === STEP VERIFY: CONFIRMAR CATALOGO =========================
//* COND=(0,NE): executa somente se passos anteriores deram RC=0.
//* IF LASTCC > 0: eleva para RC=12 se LISTCAT nao encontrar
//* o dataset - indica que a copia falhou silenciosamente.
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.ENTRADA.SEQ') ALL
  IF LASTCC > 0 THEN -
    SET MAXCC = 12
/*