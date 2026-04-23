//* ------------------------------------------------------------
//* ARQUIVO      : EBJCONC.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCONC.jcl
//*
//* CONTEXTO DIDATICO:
//* Executar a conciliação three-way do ciclo diário.
//*
//* PAPEL NO LAB:
//* Portão de controle antes do fechamento.
//*
//* FLUXO RESUMIDO:
//* 1. Entrega ao programa os DDs ENTRIN, MOVTIN, REJEIT,
//* SALDOIN, CONTA e CONCOUT.
//* 2. Produz o relatório de conciliação do dia.
//* 3. Retorna RC impeditivo quando a contagem diverge.
//*
//* OBSERVACOES:
//* - Este JCL foi ampliado para casar com o contrato real de
//* EBCONC01.
//* ------------------------------------------------------------
//EBJCONC  JOB ,'EMUNAH CONC',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//DELPREV  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.CONCIL.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//STEP1    EXEC PGM=EBCONC01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//ENTRIN   DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//REJEIT   DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=SHR
//SALDOIN  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
