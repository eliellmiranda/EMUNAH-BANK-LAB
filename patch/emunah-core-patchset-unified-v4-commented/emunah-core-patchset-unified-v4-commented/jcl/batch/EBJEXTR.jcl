//* ------------------------------------------------------------
//* ARQUIVO      : EBJEXTR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJEXTR.jcl
//*
//* CONTEXTO DIDATICO:
//* Gerar o extrato diário em ARQ.EXTRATO.GDG(+1).
//*
//* PAPEL NO LAB:
//* Produto final visível do processamento do dia.
//*
//* FLUXO RESUMIDO:
//* 1. Lê movimentos postados.
//* 2. Consulta CONTA quando necessário para contexto/saldo.
//* 3. Grava nova geração do GDG de extrato e registra
//* auditoria.
//*
//* OBSERVACOES:
//* - Nesta versão o JCL também fornece CONTA e AUDIT ao
//* programa.
//* ------------------------------------------------------------
//EBJEXTR  JOB ,'EMUNAH EXTR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=EBEXTR01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//EXTROUT  DD DSN=Z77948.EMUNAH.ARQ.EXTRATO.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
