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
//*   - ARQ.ACCR.MOV.SEQ        (apagado - EBJACCR aloca a cada
//*                              ciclo)
//*   - ARQ.FECHTO.SEQ          (apagado - EBJEOD  aloca a cada
//*                              ciclo)
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
//*
//DELSEQ   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Arquivo do dia promovido pelo EBJLOAD. Sera recriado
//*       vazio. O proximo EBJLOAD repopula a partir do STAGE.
  DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Trailer com count/hash do arquivo de entrada.
  DELETE 'Z77948.EMUNAH.ARQ.REJEITOS.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Rejeitos acumulados pelo EBJVALD via DISP=MOD.
  DELETE 'Z77948.EMUNAH.ARQ.AUDIT.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Trilha de auditoria do dia.
  DELETE 'Z77948.EMUNAH.ARQ.CONCIL.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Relatorio three-way de conciliacao (LRECL=132).
  DELETE 'Z77948.EMUNAH.ARQ.ACCR.MOV.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Movimentos de juros/tarifas. EBJACCR aloca a cada ciclo.
  DELETE 'Z77948.EMUNAH.ARQ.FECHTO.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Relatorio de fechamento. EBJEOD aloca a cada ciclo.
/*
//*
//* === STEP DELREPR: DELETAR DATASETS DE REPROCESSAMENTO ========
//*
//DELREPR  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Lancamentos recuperados pelo EBJREPR.
  DELETE 'Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Rejeitos permanentes apos reprocessamento.
  DELETE 'Z77948.EMUNAH.ARQ.RPOST.REJEITO.SEQ' NONVSAM PURGE
  SET MAXCC = 0
//*       Rejeitos da postagem de reprocessamento (EBJRPOST).
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
//*   IEFBR14 + DD NEW,CATLG mantem mesmos DCB do EBALLOC.
//*   ACCR.MOV.SEQ e FECHTO.SEQ NAO sao recriados aqui:
//*   sao alocados dinamicamente em EBJACCR/EBJEOD a cada ciclo.
//*
//RECRSEQ  EXEC PGM=IEFBR14
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Arquivo do dia recriado vazio.
//TRAILER  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Trailer/hash recriado vazio.
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=156,BLKSIZE=0)
//*           Rejeitos recriado vazio (LRECL=156).
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=128,BLKSIZE=0)
//*           Auditoria recriada vazia (LRECL=128).
//CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//*           Conciliacao three-way recriada vazia (LRECL=132).
//REPRLCT  DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Lancamentos para reprocessamento (vazio).
//REPRREJ  DD DSN=Z77948.EMUNAH.ARQ.REPR.REJPERM.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//*           Rejeitos permanentes (vazio).
//RPSTREJ  DD DSN=Z77948.EMUNAH.ARQ.RPOST.REJEITO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=156,BLKSIZE=0)
//*           Rejeitos da postagem de reprocessamento (vazio).
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
