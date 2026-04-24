//* ============================================================
//* ARQUIVO      : ALLOC.jcl
//* CAMINHO LOCAL: jcl/deploy/ALLOC.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(ALLOC)
//*
//* FINALIDADE:
//*   Alocar um subconjunto de datasets sequenciais auxiliares
//*   do laboratorio. Versao simplificada/parcial do EBALLOC.
//*
//* QUANDO USAR:
//*   - Recriar datasets especificos apos housekeeping manual
//*   - Corrigir alocacao de CONCIL.SEQ, REPR.LANCTO ou CTL.STATUS
//*     sem reexecutar a alocacao completa do ambiente
//*   Para alocacao completa do ambiente: usar EBALLOC.
//*
//* DATASETS ALOCADOS:
//*   - ARQ.CONCIL.SEQ      (LRECL=132 - relatorio de conciliacao)
//*   - ARQ.REPR.LANCTO.SEQ (LRECL=120 - lancamentos reprocessados)
//*   - ARQ.CTL.STATUS      (LRECL=80  - status do ciclo diario)
//* ============================================================
//EBALLOC  JOB ,'EMUNAH ALLOC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP ALOCSEQ: ALOCAR DATASETS SEQUENCIAIS ===============
//*   IEFBR14 e um programa nulo; toda a alocacao e feita pelos
//*   DD cards. DISP=(NEW,CATLG,DELETE): aloca, cataloga em
//*   terminacao normal e deleta em abend.
//*
//ALOCSEQ  EXEC PGM=IEFBR14
//CONCIL   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//*           Relatorio de conciliacao tres-vias (EBCONC01).
//*           LRECL=132 = largura padrao de impressora mainframe.
//REPRLCT  DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Lancamentos recuperados pelo reprocessamento (EBREPR01).
//*           Consumido pelo EBJRPOST (postagem de reprocessados).
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(1,1)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*           Arquivo de controle de status do ciclo diario.
//*           Conteudo: OPEN / EOTI / EOFI / CLOSED (padded a 8).
//*           Gravado por EBJSOD, EBJCUTF, EBJCUTE e EBJEOD.