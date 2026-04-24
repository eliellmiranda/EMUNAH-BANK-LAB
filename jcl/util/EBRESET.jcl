//* ============================================================
//* ARQUIVO      : EBRESET.jcl
//* CAMINHO LOCAL: jcl/util/EBRESET.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBRESET)
//*
//* FINALIDADE:
//*   Resetar o ambiente de laboratorio para um estado limpo,
//*   permitindo reexecutar a cadeia batch do inicio.
//*
//* O QUE ESTE JOB DELETA (datasets de saida e backup):
//*   - ARQ.LANCTO.ESDS     (VSAM ESDS - recriado vazio)
//*   - ARQ.REJEITOS.SEQ    (recriado vazio)
//*   - ARQ.AUDIT.SEQ       (recriado vazio)
//*   - ARQ.SALDO.OUT.SEQ
//*   - ARQ.CONCIL.SEQ
//*   - ARQ.EXTRATO.SEQ
//*   - ARQ.FECHTO.SEQ
//*   - ARQ.REPR.LANCTO.SEQ
//*   - ARQ.REPR.REJPERM.SEQ
//*   - BKP.CLIENTE.SEQ / BKP.CONTA.SEQ / BKP.AUDIT.SEQ
//*
//* O QUE ESTE JOB NAO TOCA (preservado):
//*   - ARQ.CLIENTE.KSDS e ARQ.CONTA.KSDS (masters de dados)
//*   - DEV.COBOL / DEV.COPY / DEV.JCL / DEV.LOADLIB
//*   - SEED.CLIENTES.SEQ e SEED.CONTAS.SEQ
//*   - ARQ.CTL.STATUS e ARQ.CTL.PROCDATE
//*   - Bases GDG e suas geracoes existentes
//*
//* SET MAXCC=0 apos cada DELETE: idempotente - nao falha se
//* o dataset ja foi deletado ou nunca existiu.
//* ============================================================
//EBRESET  JOB ,'EMUNAH RESET',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP DELSAIDA: DELETAR DATASETS DE SAIDA ================
//*
//DELSAIDA EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.LANCTO.ESDS' CLUSTER PURGE
  SET MAXCC = 0
//*       VSAM ESDS de lancamentos - sera recriado vazio no RECRIA.
  DELETE 'Z77948.EMUNAH.ARQ.REJEITOS.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Rejeitos acumulados pelo EBJVALD.
  DELETE 'Z77948.EMUNAH.ARQ.AUDIT.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Trilha de auditoria - sera recriada vazia no RECRIASEQ.
  DELETE 'Z77948.EMUNAH.ARQ.SALDO.OUT.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Arquivo de saldo de saida de execucoes anteriores.
  DELETE 'Z77948.EMUNAH.ARQ.CONCIL.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Relatorio de conciliacao do ciclo anterior.
  DELETE 'Z77948.EMUNAH.ARQ.EXTRATO.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Extrato gerado pelo EBJEXTR.
  DELETE 'Z77948.EMUNAH.ARQ.FECHTO.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Relatorio de fechamento do EBJEOD01.
/*
//*
//* === STEP DELREPR: DELETAR DATASETS DE REPROCESSAMENTO =======
//*
//DELREPR  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Lancamentos recuperados pelo EBJREPR.
  DELETE 'Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Rejeitos permanentes do EBJREPR.
/*
//*
//* === STEP DELBKP: DELETAR BACKUPS ============================
//*
//DELBKP   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.BKP.CLIENTE.SEQ' NONVSAM PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.BKP.CONTA.SEQ' NONVSAM PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.BKP.AUDIT.SEQ' NONVSAM PURGE
  SET MAXCC = 0
/*
//*
//* === STEP RECRIA: RECRIAR LANCTO.ESDS VAZIO ==================
//*   DEFINE CLUSTER identico ao do EBALLOC.
//*   Necessario porque VSAM CLUSTER nao pode ser "zerado":
//*   deve ser deletado e redefinido para ficar vazio.
//*
//RECRIA   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
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
//* === STEP RECRIASEQ: RECRIAR SEQUENCIAIS NECESSARIOS ==========
//*   IEFBR14 recria REJEITOS.SEQ e AUDIT.SEQ vazios com o mesmo
//*   DCB original, prontos para receber dados no novo ciclo.
//*
//RECRIASEQ EXEC PGM=IEFBR14
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Arquivo de rejeitos recriado vazio (LRECL=120).
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Arquivo de auditoria recriado vazio (LRECL=120).