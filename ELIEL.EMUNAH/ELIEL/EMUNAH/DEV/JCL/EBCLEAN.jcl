//EBCLEAN  JOB ,'EMUNAH CLEAN',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* ============================================================
//* ARQUIVO      : EBCLEAN.jcl
//* CAMINHO LOCAL: jcl/batch/EBCLEAN.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBCLEAN)
//*
//* FINALIDADE:
//* Limpar ou recriar os datasets de saida do EBJCONC apos
//* execucoes de teste que geraram dados inconsistentes.
//*
//* DATASETS AFETADOS (atributos extraidos do catalogo):
//*
//*   DSN                              ORG  LRECL BLKSZ RECFM VOL
//*   Z77948.EMUNAH.ARQ.REJEITOS.SEQ  PS   156   27924 FB    ZXPC02
//*   Z77948.EMUNAH.ARQ.CONCIL.SEQ    PS   132   27984 FB    ZXPC02
//*   Z77948.EMUNAH.ARQ.LANCTO.ESDS   VS   (ESDS - ver secao IDCAMS)
//*   Z77948.EMUNAH.ARQ.CONTA.KSDS    VS   (KSDS - ver secao IDCAMS)
//*
//* ATENCAO: Nao rodar com o EBJCONC em execucao simultanea.
//*          Validar status CLOSED antes de submeter.
//* ============================================================
//*
//* ==============================================================
//* ESTRATEGIA A - LIMPAR CONTEUDO (datasets ja existem)
//* Usa IEBGENER com SYSUT1=DUMMY para gravar zero registros.
//* Mantenha ativa e comente ESTRATEGIA B se os datasets
//* existem e seus atributos estao corretos no catalogo.
//* ==============================================================
//*
//* --- A1: ZERAR REJEITOS.SEQ (LRECL=156) ---
//* SYSUT1 precisa ter DCB compativel com SYSUT2 para evitar IEB311I
//CLRREJ   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DUMMY,DCB=(RECFM=FB,LRECL=156,BLKSIZE=27924)
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//            DISP=OLD
//*
//* --- A2: ZERAR CONCIL.SEQ (LRECL=132) ---
//* SYSUT1 precisa ter DCB compativel com SYSUT2 para evitar IEB311I
//CLRCNC   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DUMMY,DCB=(RECFM=FB,LRECL=132,BLKSIZE=27984)
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//            DISP=OLD
//*
//* ==============================================================
//* ESTRATEGIA B - DELETE + REALOCAR DO ZERO
//* Use se os datasets estiverem corrompidos ou com atributos
//* errados. Para ativar: comente os steps A1/A2 acima e
//* remova os //** de cada linha abaixo.
//* ==============================================================
//*
//* --- B1: DELETAR DATASETS SEQUENCIAIS ---
//**DELSEQ   EXEC PGM=IEFBR14
//**REJEIT   DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//**            DISP=(OLD,DELETE,DELETE)
//**CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//**            DISP=(OLD,DELETE,DELETE)
//*
//* --- B2: RECRIAR REJEITOS.SEQ ---
//**CRTREJ   EXEC PGM=IEFBR14
//**REJEIT   DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//**            DISP=(NEW,CATLG,DELETE),
//**            UNIT=SYSDA,
//**            VOL=SER=ZXPC02,
//**            SPACE=(KB,(12,6),RLSE),
//**            DCB=(RECFM=FB,LRECL=156,BLKSIZE=27924)
//*
//* --- B3: RECRIAR CONCIL.SEQ ---
//**CRTCNC   EXEC PGM=IEFBR14
//**CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//**            DISP=(NEW,CATLG,DELETE),
//**            UNIT=SYSDA,
//**            VOL=SER=ZXPC02,
//**            SPACE=(KB,(12,6),RLSE),
//**            DCB=(RECFM=FB,LRECL=132,BLKSIZE=27984)
//*
//* ==============================================================
//* ESTRATEGIA C - LIMPAR VSAM (ESDS e KSDS)
//*
//* ATENCAO: Esta secao apaga TODOS os registros dos arquivos
//* VSAM. So execute se tiver certeza de que os dados de teste
//* devem ser completamente removidos.
//*
//* Os parametros de DEFINE abaixo sao ESTIMADOS com base no
//* catalogo (SIZE e VOL). Confirme KEYS, KEYOFF e CISIZE
//* com o DBA ou com o LISTCAT ALL antes de ativar.
//* Para ativar: remova os //** de cada linha abaixo.
//* ==============================================================
//*
//* --- C1: LIMPAR LANCTO.ESDS (apaga e redefine vazio) ---
//**CLRESDS  EXEC PGM=IDCAMS
//**SYSPRINT DD SYSOUT=*
//**SYSIN    DD *
//**  DELETE Z77948.EMUNAH.ARQ.LANCTO.ESDS CLUSTER PURGE
//**  DEFINE CLUSTER                              -
//**         (NAME(Z77948.EMUNAH.ARQ.LANCTO.ESDS) -
//**          NONINDEXED                          -
//**          VOLUMES(ZXPL01)                     -
//**          CYLINDERS(105 10)                   -
//**          SHAREOPTIONS(2 3))                  -
//**         DATA                                 -
//**         (NAME(Z77948.EMUNAH.ARQ.LANCTO.ESDS.DATA))
//**/*
//*
//* --- C2: LIMPAR CONTA.KSDS (apaga e redefine vazio) ---
//**CLRKSDS  EXEC PGM=IDCAMS
//**SYSPRINT DD SYSOUT=*
//**SYSIN    DD *
//**  DELETE Z77948.EMUNAH.ARQ.CONTA.KSDS CLUSTER PURGE
//**  DEFINE CLUSTER                             -
//**         (NAME(Z77948.EMUNAH.ARQ.CONTA.KSDS) -
//**          INDEXED                            -
//**          VOLUMES(ZXPC02)                    -
//**          CYLINDERS(30 5)                    -
//**          KEYS(8 0)                          -
//**          SHAREOPTIONS(2 3))                 -
//**         DATA                                -
//**         (NAME(Z77948.EMUNAH.ARQ.CONTA.KSDS.DATA)) -
//**         INDEX                               -
//**         (NAME(Z77948.EMUNAH.ARQ.CONTA.KSDS.INDEX))
//**/*
//*
