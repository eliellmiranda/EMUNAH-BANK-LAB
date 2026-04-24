//* ============================================================
//* ARQUIVO      : EBLISTDS.jcl
//* CAMINHO LOCAL: jcl/util/EBLISTDS.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBLISTDS)
//*
//* FINALIDADE:
//*   Inventariar todos os datasets do laboratorio, verificando
//*   se estao catalogados e exibindo seus atributos (VOLSER,
//*   RECFM, LRECL, BLKSIZE, CREATION DATE, etc).
//*
//* QUANDO USAR:
//*   - Diagnostico de ambiente apos problemas de I/O
//*   - Verificacao de alocacao logo apos executar EBALLOC
//*   - Inventario pre-deploy para confirmar todos os DSNs
//*   - Troubleshooting de erros "DATASET NOT FOUND" na cadeia
//*
//* SAIDA:
//*   Toda saida vai para SYSPRINT no spool (sem arquivos fisicos).
//*   Arquivavel como evidencia do estado do ambiente.
//*
//* OS 4 STEPS LISTCAT POR NIVEL:
//*   LISTDEV  - Z77948.EMUNAH.DEV.*  (PDS de desenvolvimento)
//*   LISTARQ  - Z77948.EMUNAH.ARQ.*  (dados, VSAMs, GDGs)
//*   LISTSEED - Z77948.EMUNAH.SEED.* (arquivos de seed)
//*   LISTBKP  - Z77948.EMUNAH.BKP.*  (backups diversos)
//* ============================================================
//EBLISTDS JOB ,'EMUNAH LISTDS',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP LISTDEV: DATASETS DE DESENVOLVIMENTO ===============
//*   LISTCAT LEVEL lista tudo sob o nivel especificado.
//*   Inclui: COBOL, COPY, JCL, LOADLIB.
//*
//LISTDEV  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.DEV') ALL
/*
//*
//* === STEP LISTARQ: DATASETS DE DADOS =========================
//*   Inclui: KSDS de clientes/contas, ESDS de lancamentos,
//*   sequenciais (ENTRADA, REJEITOS, AUDIT, CONCIL, CTL.STATUS),
//*   GDGs (EXTRATO, SALDO, BKP.*).
//*
//LISTARQ  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.ARQ') ALL
/*
//*
//* === STEP LISTSEED: DATASETS DE SEED =========================
//*   Inclui: SEED.CLIENTES.SEQ e SEED.CONTAS.SEQ.
//*   Devem existir antes de executar EBSEED.
//*
//LISTSEED EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.SEED') ALL
/*
//*
//* === STEP LISTBKP: DATASETS DE BACKUP ========================
//*   Inclui: backups manuais e GDGs de backup.
//*   Util para verificar geracoes ativas e espaco consumido.
//*
//LISTBKP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT LEVEL('Z77948.EMUNAH.BKP') ALL
/*