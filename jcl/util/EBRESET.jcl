//* ============================================================
//* ARQUIVO      : EBRESET.jcl
//* CAMINHO LOCAL: jcl/util/EBRESET.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBRESET)
//*
//* FINALIDADE:
//*   Reset de CICLO. Limpa as saidas do dia para reexecutar
//*   a cadeia batch sobre os MESMOS masters (CLIENTE/CONTA).
//*   Util quando a cadeia falhou no meio e voce quer rodar
//*   de novo sem refazer a carga inicial.
//*
//* DIFERENCA PARA EBRESETF:
//*   - EBRESET   = reset de CICLO (este job - preserva masters,
//*                 CTL.STATUS, CTL.PROCDATE e GDGs)
//*   - EBRESETF  = reset de FABRICA (zera tudo, exceto fontes
//*                 e LOADLIB) - rodar antes de EBSEED + EBJCLLD
//*
//* O QUE ESTE JOB DELETA / RECRIA VAZIO:
//*   - ARQ.LANCTO.ESDS         (DELETE CLUSTER + DEFINE)
//*   - ARQ.ENTRADA.SEQ         (recriado vazio LRECL=120)
//*   - ARQ.ENTRADA.TRAILER.SEQ (recriado vazio LRECL=80)
//*   - ARQ.REJEITOS.SEQ        (recriado vazio LRECL=156)
//*   - ARQ.AUDIT.SEQ           (recriado vazio LRECL=128)
//*   - ARQ.CONCIL.SEQ          (recriado vazio LRECL=132)
//*   - ARQ.ACCR.MOV.SEQ        (recriado vazio LRECL=120)
//*   - ARQ.FECHTO.SEQ          (recriado vazio LRECL=132)
//*   - ARQ.REPR.LANCTO.SEQ     (recriado vazio LRECL=120)
//*   - ARQ.REPR.REJPERM.SEQ    (recriado vazio LRECL=150)
//*   - ARQ.RPOST.REJEITO.SEQ   (recriado vazio LRECL=156)
//*
//* O QUE ESTE JOB NAO TOCA (preservado):
//*   - ARQ.CLIENTE.KSDS e ARQ.CONTA.KSDS (masters)
//*   - ARQ.CTL.STATUS e ARQ.CTL.PROCDATE (controle do ciclo)
//*   - DEV.COBOL / DEV.COPY / DEV.JCL / DEV.LOADLIB / DEV.REXX
//*   - SEED.CLIENTES.SEQ e SEED.CONTAS.SEQ
//*   - STAGE.ENTRADA.SEQ (permite re-promover o mesmo arquivo
//*                        do dia via EBJWAIT/EBJLOAD)
//*   - GDGs (SALDO, EXTRATO, BKP.*) e suas geracoes
//*
//* PROXIMO PASSO APOS RODAR ESTE JOB:
//*   - Ajustar CTL.STATUS para CLOSED se nao estiver (via
//*     EBCTL01 ou edicao manual no ISPF)
//*   - Reexecutar a cadeia: EBJPRECK -> EBJSOD -> ... -> EBJEOD
//*
//* SCRATCH em todos os DELETE: remove do VTOC mesmo quando o
//* catalogo esta dessincronizado. Previne IGD17001I em reruns.
//* SET MAXCC=0 apos cada DELETE: idempotente. Nao falha se o
//* dataset ja foi deletado ou nunca existiu.
//* ============================================================
//EBRESET  JOB ,'EMUNAH RESET',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP DELLCT: DELETAR LANCTO.ESDS =========================
//*   VSAM CLUSTER nao pode ser "esvaziado" - precisa DELETE +
//*   redefinir. Os outros VSAMs (CLIENTE/CONTA) NAO sao tocados
//*   - sao masters preservados.
//*
//DELLCT   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.LANCTO.ESDS' CLUSTER PURGE
  SET MAXCC = 0
/*
//*
//* === STEP DELSEQ: DELETAR SEQUENCIAIS DO CICLO ================
//*   SCRATCH garante remocao do VTOC mesmo se o catalogo estiver
//*   dessincronizado (previne IGD17001I em reruns).
//*
//DELSEQ   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.REJEITOS.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.AUDIT.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.CONCIL.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.ACCR.MOV.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.FECHTO.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
/*
//*
//* === STEP DELREPR: DELETAR DATASETS DE REPROCESSAMENTO ========
//*
//DELREPR  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
  DELETE 'Z77948.EMUNAH.ARQ.RPOST.REJEITO.SEQ' NONVSAM SCRATCH PURGE
  SET MAXCC = 0
/*
//*
//* === STEP DEFLCT: REDEFINIR LANCTO.ESDS VAZIO =================
//*   DEFINE CLUSTER identico ao do EBALLOC. Necessario porque
//*   VSAM nao aceita truncate.
//*
//DEFLCT   EXEC PGM=IDCAMS
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
//* === STEP RECRSEQ: RECRIAR SEQUENCIAIS NECESSARIOS ============
//*   IEFBR14 + DD NEW,CATLG recria todos vazios com DCB correto.
//*   ACCR.MOV.SEQ e FECHTO.SEQ incluidos: EBJACCR e EBJEOD usam
//*   DISP=OLD e exigem que o dataset exista antes de executar.
//*
//RECRSEQ  EXEC PGM=IEFBR14
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//TRAILER  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=156,BLKSIZE=0)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=128,BLKSIZE=0)
//CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//ACCRMOV  DD DSN=Z77948.EMUNAH.ARQ.ACCR.MOV.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//FECHTO   DD DSN=Z77948.EMUNAH.ARQ.FECHTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,2)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//REPRLCT  DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//REPRREJ  DD DSN=Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//RPSTREJ  DD DSN=Z77948.EMUNAH.ARQ.RPOST.REJEITO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=156,BLKSIZE=0)
//*
//* === STEP LISTRES: EVIDENCIA POS-RESET ========================
//*   LISTCAT mostra os datasets recriados vazios e os masters
//*   intactos.
//*
//LISTRES  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.LANCTO.ESDS')   ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CLIENTE.KSDS')
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CONTA.KSDS')
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS')
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.PROCDATE')
/*