//* ------------------------------------------------------------
//* ARQUIVO      : EBALLOC.jcl
//* CAMINHO LOCAL: jcl/deploy/EBALLOC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBALLOC)
//* FINALIDADE:
//* Alocar todos os datasets necessarios para o laboratorio.
//* Executar uma unica vez na preparacao inicial do ambiente,
//* seguido de EBDEFGDG (bases GDG) e EBSEED (carga inicial).
//*
//* DATASETS CRIADOS:
//* - PDS de desenvolvimento (COBOL, COPY, JCL, LOADLIB)
//* - VSAM KSDS (Clientes, Contas)
//* - VSAM ESDS (Lancamentos)
//* - Sequenciais de apoio: ENTRADA, ENTRADA.TRAILER, REJEITOS,
//*   AUDIT, CONCIL, REPR.LANCTO, REPR.REJPERM
//* - Controle de ciclo: CTL.STATUS, CTL.PROCDATE
//* - Parametros: PARM.JUROS.CONFIG
//* - Sequenciais de seed: CLIENTES, CONTAS
//*
//* DATASETS NAO ALOCADOS AQUI (criados dinamicamente):
//* - ARQ.ACCR.MOV.SEQ    (NEW em EBJACCR a cada ciclo)
//* - ARQ.FECHTO.SEQ      (NEW em EBJEOD  a cada ciclo)
//* - GDGs: definidos via EBDEFGDG, geracoes criadas pelos jobs
//* ------------------------------------------------------------
//EBALLOC  JOB ,'EMUNAH ALLOC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: PDS DE DESENVOLVIMENTO ===
//*
//ALOCPDS  EXEC PGM=IEFBR14
//COBOL    DD DSN=Z77948.EMUNAH.DEV.COBOL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(30,10,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0,DSORG=PO)
//* PDS dos fontes COBOL.
//COPY     DD DSN=Z77948.EMUNAH.DEV.COPY,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0,DSORG=PO)
//* PDS dos copybooks.
//JCL      DD DSN=Z77948.EMUNAH.DEV.JCL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(20,10,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0,DSORG=PO)
//* PDS dos JCLs de desenvolvimento.
//LOADLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(CYL,(5,2,10)),
//             DCB=(RECFM=U,BLKSIZE=32760,DSORG=PO)
//* PDS dos modulos linkeditados (executaveis).
//*
//* === STEP 2: VSAM KSDS - CLIENTES ===
//*
//VSAMCLI  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.CLIENTE.KSDS' CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER -
    (NAME('Z77948.EMUNAH.ARQ.CLIENTE.KSDS') -
     INDEXED -
     RECORDS(500 100) -
     RECORDSIZE(80 80) -
     KEYS(5 0) -
     SHAREOPTIONS(2 3)) -
    DATA -
    (NAME('Z77948.EMUNAH.ARQ.CLIENTE.KSDS.DATA')) -
    INDEX -
    (NAME('Z77948.EMUNAH.ARQ.CLIENTE.KSDS.INDEX'))
/*
//*
//* === STEP 3: VSAM KSDS - CONTAS ===
//*
//VSAMCNT  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.CONTA.KSDS' CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER -
    (NAME('Z77948.EMUNAH.ARQ.CONTA.KSDS') -
     INDEXED -
     RECORDS(1000 200) -
     RECORDSIZE(100 100) -
     KEYS(12 0) -
     SHAREOPTIONS(2 3)) -
    DATA -
    (NAME('Z77948.EMUNAH.ARQ.CONTA.KSDS.DATA')) -
    INDEX -
    (NAME('Z77948.EMUNAH.ARQ.CONTA.KSDS.INDEX'))
/*
//*
//* === STEP 4: VSAM ESDS - LANCAMENTOS ===
//*
//VSAMLCT  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.LANCTO.ESDS' CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER -
    (NAME('Z77948.EMUNAH.ARQ.LANCTO.ESDS') -
     NONINDEXED -
     RECORDS(5000 1000) -
     RECORDSIZE(120 120) -
     SHAREOPTIONS(2 3)) -
    DATA -
    (NAME('Z77948.EMUNAH.ARQ.LANCTO.ESDS.DATA'))
/*
//*
//* === STEP 5: SEQUENCIAIS DE APOIO ===
//*
//ALOCSEQ  EXEC PGM=IEFBR14
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Arquivo de transacoes do dia - populado pelo EBJLOAD.
//TRAILER  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//* Trailer do arquivo de entrada: data(8)+count(7)+hash(15).
//* Lido pelo EBJWAIT para validar integridade do ENTRADA.SEQ.
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Rejeitos da validacao - gravado pelo EBJVALD, rotacionado
//* pelo EBJHKREJ ao fim do ciclo.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Trilha de auditoria acumulada via DISP=MOD pelos programas.
//* Rotacionada pelo EBJHKAUD ao fim do ciclo.
//CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//* Resultado da conciliacao tres-vias (EBCONC01). LRECL=132.
//REPRLCT  DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Lancamentos recuperados pelo EBJREPR para repostagem.
//REPRREJ  DD DSN=Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Rejeitos permanentes apos reprocessamento (EBJREPR).
//*
//* === STEP 6: CONTROLE DE CICLO E PARAMETROS ===
//*
//ALOCCTL  EXEC PGM=IEFBR14
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=8,BLKSIZE=0)
//* Status do ciclo: OPEN/EOTI/EOFI/CLOSED (8 bytes).
//* Gravado por EBJSOD, EBJCUTF, EBJCUTE, EBJEOD via EBCTL01.
//CTLDATE  DD DSN=Z77948.EMUNAH.ARQ.CTL.PROCDATE,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=8,BLKSIZE=0)
//* Data de processamento corrente: YYYYMMDD (8 bytes).
//* Gravado pelo EBJSOD, lido por todos os programas que
//* precisam carimbar data nos registros de saida.
//PARMJUR  DD DSN=Z77948.EMUNAH.PARM.JUROS.CONFIG,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//* Parametros de juros e tarifas por tipo de conta (80 bytes
//* posicionais). Lido pelo EBACCR01 via DD PARMLIB.
//*
//* === STEP 7: SEQUENCIAIS DE SEED ===
//*
//ALOCSEED EXEC PGM=IEFBR14
//SEEDCLI  DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//* Dados iniciais de clientes para carga via EBSEED.
//SEEDCNT  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//* Dados iniciais de contas para carga via EBSEED.