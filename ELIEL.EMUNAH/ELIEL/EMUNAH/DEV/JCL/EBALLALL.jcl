//* ============================================================
//* ARQUIVO      : EBALLALL.jcl
//* CAMINHO LOCAL: jcl/deploy/EBALLALL.jcl
//* HOST / PDS   : ELIEL.EMUNAH.DEV.JCL(EBALLALL)
//*
//* FINALIDADE:
//*   Bootstrap completo do laboratorio EMUNAH BANK.
//*   Cria do zero TODOS os datasets sob ELIEL.EMUNAH.*:
//*   - 3 VSAM (CLIENTE.KSDS, CONTA.KSDS, LANCTO.ESDS)
//*   - 6 GDG bases (EXTRATO, SALDO, BKP.AUDIT/CLIENTE/CONTA/REJEITOS)
//*   - 9 PDSE libraries (DEV.*, HML.*, PRD.*, LOADLIB)
//*   - 1 PDS classico (PARM.JUROS.CONFIG)
//*   - 14 sequenciais (ARQ.*, SEED.*, STAGE.*, BAK.*, CTL.*)
//*
//* QUANDO USAR:
//*   - Setup inicial em ambiente novo (executar UMA UNICA VEZ)
//*   - Recuperacao apos EBRESET ou disaster recovery
//*   - Bootstrap em outro userid (ajustar HLQ no fonte)
//*
//* ATENCAO:
//*   - VSAM: usa DELETE+DEFINE com MAXCC=0 (idempotente)
//*   - Demais: NEW,CATLG,DELETE - falha se ja existirem
//*   - Para re-executar so a parte VSAM: rodar STEPs DEFCLI/CONTA/LANCTO
//*   - Para limpar antes: rodar EBRESET primeiro
//*
//* ORDEM DOS STEPS:
//*   1. DEFCLI    - VSAM CLIENTE.KSDS
//*   2. DEFCNT    - VSAM CONTA.KSDS
//*   3. DEFLAN    - VSAM LANCTO.ESDS
//*   4. DEFGDG    - 6 bases de GDG (IDCAMS unico)
//*   5. ALCPDSE   - PDSE libraries (DEV/HML/PRD)
//*   6. ALCLOAD   - LOADLIB (PDSE com RECFM=U)
//*   7. ALCPDS    - PDS classico (PARM.JUROS.CONFIG)
//*   8. ALCSEQ1   - sequenciais ARQ.* operacionais
//*   9. ALCSEQ2   - sequenciais CTL.*, SEED.*, STAGE.*, BAK.*
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = todos os datasets criados/recriados com sucesso
//*   RC 8+ = falha em algum step - verificar SYSPRINT do step
//* ============================================================
//EBALLALL JOB ,'EMUNAH ALOC ALL',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* ============================================================
//* === BLOCO 1: VSAM CLUSTERS ==================================
//* ============================================================
//*
//* === STEP DEFCLI: CLIENTE.KSDS ===============================
//*   KEYS(5 0)        - chave de 5 bytes na posicao 0
//*                      (CLI-ID-CLIENTE no CPCLI001)
//*   RECORDSIZE(80 80)- registros de tamanho fixo 80 bytes
//*   IXLVL(1)         - nivel de indice basico
//*
//DEFCLI   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE ELIEL.EMUNAH.ARQ.CLIENTE.KSDS CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER ( -
    NAME(ELIEL.EMUNAH.ARQ.CLIENTE.KSDS) -
    INDEXED -
    KEYS(5 0) -
    RECORDSIZE(80 80) -
    CYLINDERS(30 5) -
    VOLUMES(ZXPL01) -
    SHAREOPTIONS(2 3) ) -
    DATA  (NAME(ELIEL.EMUNAH.ARQ.CLIENTE.KSDS.DATA)) -
    INDEX (NAME(ELIEL.EMUNAH.ARQ.CLIENTE.KSDS.INDEX))
/*
//*
//* === STEP DEFCNT: CONTA.KSDS =================================
//*   KEYS(12 0)        - chave composta de 12 bytes
//*                       (CNT-ID-CLIENTE 5 + CNT-AGENCIA 4 +
//*                        CNT-NUM-CONTA primeiros 3 - ajustar
//*                        conforme CPCNT001)
//*   RECORDSIZE(100 100) - registros fixos de 100 bytes
//*
//DEFCNT   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE ELIEL.EMUNAH.ARQ.CONTA.KSDS CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER ( -
    NAME(ELIEL.EMUNAH.ARQ.CONTA.KSDS) -
    INDEXED -
    KEYS(12 0) -
    RECORDSIZE(100 100) -
    CYLINDERS(30 5) -
    VOLUMES(ZXPC02) -
    SHAREOPTIONS(2 3) ) -
    DATA  (NAME(ELIEL.EMUNAH.ARQ.CONTA.KSDS.DATA)) -
    INDEX (NAME(ELIEL.EMUNAH.ARQ.CONTA.KSDS.INDEX))
/*
//*
//* === STEP DEFLAN: LANCTO.ESDS ================================
//*   NONINDEXED          - ESDS (sem chave, leitura sequencial)
//*   RECORDSIZE(120 120) - mesmo layout do CPLCT001
//*   Nao tem componente .INDEX
//*
//DEFLAN   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE ELIEL.EMUNAH.ARQ.LANCTO.ESDS CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER ( -
    NAME(ELIEL.EMUNAH.ARQ.LANCTO.ESDS) -
    NONINDEXED -
    RECORDSIZE(120 120) -
    CYLINDERS(105 10) -
    VOLUMES(ZXPL01) -
    SHAREOPTIONS(2 3) ) -
    DATA (NAME(ELIEL.EMUNAH.ARQ.LANCTO.ESDS.DATA))
/*
//*
//* ============================================================
//* === BLOCO 2: GDG BASES ======================================
//* ============================================================
//*
//* === STEP DEFGDG: 6 bases de GDG ==============================
//*   LIMIT(5)  - mantem ate 5 geracoes (G0001V00..G0005V00)
//*   SCRATCH   - apaga geracao mais antiga ao exceder LIMIT
//*   NOEMPTY   - so apaga a mais antiga (FIFO)
//*   Geracoes individuais sao criadas pelos jobs com DCB local.
//*
//DEFGDG   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE ELIEL.EMUNAH.ARQ.EXTRATO.GDG  GDG FORCE
  DELETE ELIEL.EMUNAH.ARQ.SALDO.GDG    GDG FORCE
  DELETE ELIEL.EMUNAH.BKP.AUDIT.GDG    GDG FORCE
  DELETE ELIEL.EMUNAH.BKP.CLIENTE.GDG  GDG FORCE
  DELETE ELIEL.EMUNAH.BKP.CONTA.GDG    GDG FORCE
  DELETE ELIEL.EMUNAH.BKP.REJEITOS.GDG GDG FORCE
  SET MAXCC = 0
  DEFINE GDG (NAME(ELIEL.EMUNAH.ARQ.EXTRATO.GDG)  LIMIT(5) SCRATCH NOEMPTY)
  DEFINE GDG (NAME(ELIEL.EMUNAH.ARQ.SALDO.GDG)    LIMIT(5) SCRATCH NOEMPTY)
  DEFINE GDG (NAME(ELIEL.EMUNAH.BKP.AUDIT.GDG)    LIMIT(5) SCRATCH NOEMPTY)
  DEFINE GDG (NAME(ELIEL.EMUNAH.BKP.CLIENTE.GDG)  LIMIT(5) SCRATCH NOEMPTY)
  DEFINE GDG (NAME(ELIEL.EMUNAH.BKP.CONTA.GDG)    LIMIT(5) SCRATCH NOEMPTY)
  DEFINE GDG (NAME(ELIEL.EMUNAH.BKP.REJEITOS.GDG) LIMIT(5) SCRATCH NOEMPTY)
/*
//*
//* ============================================================
//* === BLOCO 3: PDSE LIBRARIES =================================
//* ============================================================
//*
//* === STEP ALCPDSE: PDSE de fontes/copybooks/jcl ==============
//*   DSNTYPE=LIBRARY  - PDSE (suporta membros longos, sem
//*                      necessidade de compress)
//*   RECFM=FB LRECL=80 - padrao para fontes COBOL/JCL/COPY
//*
//ALCPDSE  EXEC PGM=IEFBR14
//DEVCOB   DD DSN=ELIEL.EMUNAH.DEV.COBOL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//DEVCPY   DD DSN=ELIEL.EMUNAH.DEV.COPY,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//DEVDCL   DD DSN=ELIEL.EMUNAH.DEV.DCLGEN,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(3,2,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//DEVJCL   DD DSN=ELIEL.EMUNAH.DEV.JCL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(8,4,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//DEVMAP   DD DSN=ELIEL.EMUNAH.DEV.MAPLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(3,2,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//DEVRXX   DD DSN=ELIEL.EMUNAH.DEV.REXX,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//HMLCOB   DD DSN=ELIEL.EMUNAH.HML.COBOL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//HMLJCL   DD DSN=ELIEL.EMUNAH.HML.JCL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//PRDJCL   DD DSN=ELIEL.EMUNAH.PRD.JCL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//PRDPRM   DD DSN=ELIEL.EMUNAH.PRD.PARMLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//*
//* === STEP ALCLOAD: LOADLIB (PDSE de modulos executaveis) =====
//*   RECFM=U         - undefined (formato de modulo carregavel)
//*   BLKSIZE=4096    - tamanho de bloco padrao para LOAD
//*   LRECL nao se aplica para RECFM=U
//*   DSNTYPE=LIBRARY - PDSE
//*
//ALCLOAD  EXEC PGM=IEFBR14
//LOADLIB  DD DSN=ELIEL.EMUNAH.DEV.LOADLIB,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(6,3,0)),
//             DSNTYPE=LIBRARY,
//             DCB=(RECFM=U,BLKSIZE=4096)
//SYSPRINT DD SYSOUT=*
//*
//* === STEP ALCPDS: PDS classico (parametros de juros) =========
//*   PDS classico (nao PDSE) - membros pequenos, raras updates
//*   Direcionario alocado explicitamente (10 entradas)
//*
//ALCPDS   EXEC PGM=IEFBR14
//PARMJUR  DD DSN=ELIEL.EMUNAH.PARM.JUROS.CONFIG,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(2,1,10)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//*
//* ============================================================
//* === BLOCO 4: SEQUENCIAIS ====================================
//* ============================================================
//*
//* === STEP ALCSEQ1: ARQ.* operacionais ========================
//*   Datasets de movimento, conciliacao, accruals e rejeitos.
//*   Usados durante a cadeia diaria EBJSOD->EBJEOD.
//*
//ALCSEQ1  EXEC PGM=IEFBR14
//ACCRMOV  DD DSN=ELIEL.EMUNAH.ARQ.ACCR.MOV.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//AUDIT    DD DSN=ELIEL.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//CONCIL   DD DSN=ELIEL.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//CONCBAK  DD DSN=ELIEL.EMUNAH.ARQ.CONCIL.SEQBCKP,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//ENTRADA  DD DSN=ELIEL.EMUNAH.ARQ.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//ENTTRL   DD DSN=ELIEL.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//REJEIT   DD DSN=ELIEL.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//REPRLAN  DD DSN=ELIEL.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//*
//* === STEP ALCSEQ2: CTL.*, SEED.*, STAGE.*, BAK.* =============
//*   Datasets de controle, carga inicial e staging externo.
//*   CTL.STATUS deve ser inicializado com "CLOSED" antes do
//*   primeiro EBJSOD (gravar via IEBGENER apos esta alocacao).
//*
//ALCSEQ2  EXEC PGM=IEFBR14
//CTLDATE  DD DSN=ELIEL.EMUNAH.ARQ.CTL.PROCDATE,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//CTLSTAT  DD DSN=ELIEL.EMUNAH.ARQ.CTL.STATUS,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=8,BLKSIZE=0)
//SEEDCLI  DD DSN=ELIEL.EMUNAH.SEED.CLIENTES.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//SEEDCNT  DD DSN=ELIEL.EMUNAH.SEED.CONTAS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=100,BLKSIZE=0)
//STAGE    DD DSN=ELIEL.EMUNAH.STAGE.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//BAKCNT   DD DSN=ELIEL.EMUNAH.BAK.CONTA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=41,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//*
//* ============================================================
//* === FIM EBALLALL ============================================
//* PROXIMOS PASSOS APOS EXECUCAO:
//*   1. Inicializar CTL.STATUS com "CLOSED" (IEBGENER)
//*   2. Carregar SEED.CLIENTES.SEQ e SEED.CONTAS.SEQ (upload)
//*   3. Submeter EBSEED para popular CLIENTE.KSDS e CONTA.KSDS
//*   4. Submeter EBDEPLOY para compilar todos os programas
//*   5. Submeter EBJSOD para abrir o primeiro ciclo batch
//* ============================================================
