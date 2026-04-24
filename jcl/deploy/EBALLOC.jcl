//* ============================================================
//* ARQUIVO      : EBALLOC.jcl
//* CAMINHO LOCAL: jcl/deploy/EBALLOC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBALLOC)
//*
//* FINALIDADE:
//*   Alocar TODOS os datasets necessarios para o laboratorio.
//*   Executar UMA UNICA VEZ na preparacao inicial do ambiente,
//*   na seguinte ordem:
//*     1. EBALLOC  (este job)
//*     2. EBDEFGDG (define bases GDG)
//*     3. EBSEED   (carga inicial dos KSDS)
//*
//* DATASETS NAO ALOCADOS AQUI (criados dinamicamente pelos jobs):
//*   - ARQ.ACCR.MOV.SEQ  (NEW em EBJACCR a cada ciclo)
//*   - ARQ.FECHTO.SEQ    (NEW em EBJEOD  a cada ciclo)
//*   - GDGs: bases definidas em EBDEFGDG; geracoes (+1) criadas
//*     pelos jobs EBJEXTR, EBJSNAP, EBJBCKPD, EBJHKAUD, EBJHKREJ
//*
//* ESTRUTURA DOS 7 STEPS:
//*   ALOCPDS  - PDS de desenvolvimento (COBOL/COPY/JCL/LOADLIB)
//*   VSAMCLI  - VSAM KSDS de clientes
//*   VSAMCNT  - VSAM KSDS de contas
//*   VSAMLCT  - VSAM ESDS de lancamentos
//*   ALOCSEQ  - Arquivos sequenciais de apoio e controle
//*   ALOCCTL  - Datasets de controle de ciclo e parametros
//*   ALOCSEED - Arquivos seed (entrada para EBSEED)
//* ============================================================
//EBALLOC  JOB ,'EMUNAH ALLOC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP ALOCPDS: PDS DE DESENVOLVIMENTO ====================
//*   IEFBR14 nao executa logica; os PDS sao criados pelos DD.
//*   DSORG=PO = Partitioned Organization (PDS).
//*   SPACE CYL para LOADLIB (modulos maiores), TRK para fontes.
//*
//ALOCPDS  EXEC PGM=IEFBR14
//COBOL    DD DSN=Z77948.EMUNAH.DEV.COBOL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(30,10,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0,DSORG=PO)
//*           PDS dos fontes COBOL. Terceiro numero (10) = diretorios.
//COPY     DD DSN=Z77948.EMUNAH.DEV.COPY,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0,DSORG=PO)
//*           PDS dos copybooks (layouts, telas, DB2).
//JCL      DD DSN=Z77948.EMUNAH.DEV.JCL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(20,10,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0,DSORG=PO)
//*           PDS dos JCLs de desenvolvimento.
//LOADLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(CYL,(5,2,10)),
//             DCB=(RECFM=U,BLKSIZE=32760,DSORG=PO)
//*           PDS dos modulos executaveis. RECFM=U = undefined
//*           (formato padrao de LOADLIB). BLKSIZE=32760 = maximo.
//*
//* === STEP VSAMCLI: VSAM KSDS DE CLIENTES ====================
//*   DELETE + SET MAXCC=0: idempotente (nao falha no primeiro run).
//*   KEYS(5 0): chave de 5 bytes na posicao 0 = CLI-CPF.
//*   SHAREOPTIONS(2 3): multiplos jobs leitores, 1 atualizador.
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
//* === STEP VSAMCNT: VSAM KSDS DE CONTAS =======================
//*   KEYS(12 0): chave de 12 bytes na posicao 0 =
//*   CNT-AGENCIA(4) + CNT-NUM-CONTA(8) = chave composta.
//*   RECORDSIZE(100 100): LRECL fixo de 100 bytes (CPCNT001).
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
//* === STEP VSAMLCT: VSAM ESDS DE LANCAMENTOS ==================
//*   NONINDEXED = ESDS (sem chave). Acesso sequencial ou por RBA.
//*   Gravacao sempre por WRITE (append); sem REWRITE nem DELETE.
//*   RECORDSIZE(120 120): LRECL fixo de 120 bytes (CPLCT001).
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
//* === STEP ALOCSEQ: SEQUENCIAIS DE APOIO ======================
//*
//ALOCSEQ  EXEC PGM=IEFBR14
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Lancamentos do dia. Populado pelo EBJLOAD a partir
//*           do STAGE. Consumido pelo EBJVALD (EBVALI01).
//TRAILER  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Trailer do arquivo de entrada: data(8)+count(7)+hash(15).
//*           Lido pelo EBJWAIT para validar integridade do ENTRADA.SEQ.
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Rejeitos acumulados via DISP=MOD pelo EBJVALD.
//*           Rotacionado pelo EBJHKREJ ao fim do ciclo.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Trilha de auditoria acumulada via DISP=MOD.
//*           Rotacionada pelo EBJHKAUD ao fim do ciclo.
//CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//*           Resultado da conciliacao (EBCONC01). LRECL=132.
//REPRLCT  DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Lancamentos recuperados pelo EBJREPR para repostagem.
//REPRREJ  DD DSN=Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Rejeitos permanentes apos reprocessamento (EBJREPR).
//*
//* === STEP ALOCCTL: CONTROLE DE CICLO E PARAMETROS ============
//*
//ALOCCTL  EXEC PGM=IEFBR14
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=8,BLKSIZE=0)
//*           Status do ciclo: OPEN/EOTI/EOFI/CLOSED (8 bytes).
//*           Gravado por EBCTL01 (ou IEBGENER nos jobs SOD/CUT).
//CTLDATE  DD DSN=Z77948.EMUNAH.ARQ.CTL.PROCDATE,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=8,BLKSIZE=0)
//*           Data de processamento corrente: YYYYMMDD (8 bytes).
//*           Gravado pelo EBJSOD, lido pelos programas que precisam
//*           carimbar data nos registros de saida.
//PARMJUR  DD DSN=Z77948.EMUNAH.PARM.JUROS.CONFIG,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Parametros de juros e tarifas (80 bytes posicionais).
//*           Lido pelo EBACCR01 via DD PARMLIB.
//*
//* === STEP ALOCSEED: ARQUIVOS SEED ============================
//*
//ALOCSEED EXEC PGM=IEFBR14
//SEEDCLI  DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Dados iniciais de clientes para carga via EBSEED.
//SEEDCNT  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//*           Dados iniciais de contas para carga via EBSEED.